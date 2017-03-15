# Cut a release
# -------------
#
# 2. git branch 4.3.x.x (in gpdb repo)
# 1. (before any changes on the release branch) tag the branch point as 4.3.x.x-rc1
# 3. Update release version number, (~~modify pipeline~~); commit & push
# 4. Create secrets file in gpdb-ci-deployments repo; commit & push
# 5. fly set-pipeline new release pipeline
# 6. Create S3 bucket for release pipeline, including permissions and versioning (Use a bootstrap job in the pipeline)
# 7. Kick off ccache job
#
# Upload to PivNet
# ----------------
#
# 1. Upload to PivNet

import boto3
import botocore
import collections
import datetime
from distutils.version import StrictVersion
import errno
import json
import os
import re
import ruamel.yaml
import sys
import subprocess

SECRETS_FILE_43_STABLE = 'gpdb-4.3_STABLE-ci-secrets.yml'
SHARED_CONCOURSE_AWS_ACCOUNT_NUMBER = '189358390367'

SECRETS_NOT_FOUND_ERROR = u"""\
Error. gpdb-ci-deployments (the secrets repo) not found. Two possible reasons:
  1. You are running this script from a subdirectory of the gpdb4 repo
     Currently, you must run this from the root of the gpdb4 repo
  2. You do not have the gpdb-ci-deployments repo cloned down.
     Please have gpdb-ci-deployments (the secrets repo) as a sibling directory at ../gpdb-ci-deployments
     so that your tree looks like:

\u2514\u2500\u2500 workspace   #or similar
    \u2514\u2500\u2500 gpdb-ci-deployments
    \u2514\u2500\u2500 gpdb4
"""


class CommandRunner(object):
  def __init__(self, cwd=None):
    self.cwd = cwd or os.getcwd()

  def get_subprocess_output(self, cmd):
    p = subprocess.Popen(cmd, cwd=self.cwd, stdout=subprocess.PIPE)
    output = p.stdout.read().strip()
    p.stdout.close()
    status = p.wait()
    return output if status == 0 else None

  def subprocess_is_successful(self, cmd):
    return 0 == subprocess.call(cmd, cwd=self.cwd)


class Environment(object):
  def __init__(self, command_runner=None, printer=None):
    self.command_runner = command_runner or CommandRunner()
    self.printer = printer or Printer()

  def check_dependencies(self):
    git_version_output = self.get_program_version('git')
    if not git_version_output: return False
    git_version = git_version_output.split()[2]
    fly_version = self.get_program_version('fly')
    if not fly_version: return False
    pip_install_success = self.command_runner.subprocess_is_successful(
        ('pip', 'install', '-r', 'ci/release/requirements.txt'))

    return (
        StrictVersion(git_version) > StrictVersion('1.9.9') and
        StrictVersion(fly_version) >= StrictVersion('2.6.0') and
        pip_install_success)

  def get_program_version(self, program):
    try:
      program_version = self.command_runner.get_subprocess_output(
          (program, '--version'))
    except OSError, e:
      if e.args[0] == errno.ENOENT:
        self.printer.print_msg(program + ' not found. Is it installed?')
        return None
      else:
        raise
    return program_version


  def check_git_can_pull(self):
    result = self.command_runner.subprocess_is_successful(
        ('git', 'ls-remote', 'origin', 'refs/connectivity-test'))
    return result

  def check_git_status(self):
    return (
        (self.command_runner.get_subprocess_output(
            ("git", "rev-parse", "--show-toplevel")) == os.path.abspath(self.command_runner.cwd)) and
        (self.command_runner.get_subprocess_output(
            ("git", "status", "--porcelain")) == '')
    )

  def check_git_head_is_latest(self):
    head_sha = self.command_runner.get_subprocess_output(
        ('git', 'rev-parse', 'HEAD'))
    remote_master_sha = self.command_runner.get_subprocess_output(
        ('git', 'ls-remote', 'origin', 'master')) or ''
    return remote_master_sha.startswith(head_sha)

  def check_has_file(self, path, os_path_exists=os.path.exists):
    return os_path_exists(os.path.join(self.command_runner.cwd, path))

  def path(self, *path_segments):
    return os.path.join(self.command_runner.cwd, *path_segments)


class Aws(object):
  def __init__(self):
    self.s3 = boto3.resource('s3')
    self.iam = boto3.client('iam')

  def get_botobucket(self, bucket_name):
    return self.s3.Bucket(bucket_name)

  def bucket_exists(self, bucket):
    try:
      bucket.load()
      return True
    except botocore.exceptions.ClientError as e:
      if e.response['Error']['Code'] == '404':
        return False
      raise e

  def check_iam_user_within_account(self, expected_account):
    return expected_account in self.iam.get_user()['User']['Arn']


class PipelineFileEditor(object):
  def __init__(self, gpdb_environment):
    self.gpdb_environment = gpdb_environment

  def edit_pipeline_for_release(self, pipeline_file):
    with open(self.gpdb_environment.path(pipeline_file), 'r') as fin:
      pipeline_before = fin.read()
      pipeline_with_interpolation_braces_quoted = re.sub(r'({{.*}})', r"'\1'", pipeline_before)
      pipeline = ruamel.yaml.load(pipeline_with_interpolation_braces_quoted, ruamel.yaml.RoundTripLoader)

    self.walk_and_edit_pipeline(pipeline)

    with open(self.gpdb_environment.path(pipeline_file), 'w') as fout:
      pipeline_after_ruamel_processing = ruamel.yaml.dump(pipeline, Dumper=ruamel.yaml.RoundTripDumper)
      pipeline_with_interpolation_brace_quoting_removed = re.sub('["\']' r'({{.*}})' '[\'"]', r"\1", pipeline_after_ruamel_processing)
      fout.write(pipeline_with_interpolation_brace_quoting_removed)

  def walk_and_edit_pipeline(self, pipeline_hunk):

    if isinstance(pipeline_hunk, list):
      pipeline_hunk[:] = [item for item in pipeline_hunk if not self.should_delete(item)]
      for item in pipeline_hunk:
        self.maybe_add_trigger(item)
        self.walk_and_edit_pipeline(item)

    elif isinstance(pipeline_hunk, dict):
      for key, value in pipeline_hunk.items():
        if self.should_delete(value):
          del pipeline_hunk[key]
        else:
          self.maybe_add_trigger(value)
          self.walk_and_edit_pipeline(value)

  def should_delete(self, node):
    if isinstance(node, dict):
      return node.get('gpdb_release') == 'delete'
    return False

  def maybe_add_trigger(self, node):
    if isinstance(node, dict):
      if node.get('gpdb_release') == 'add_trigger':
        del node['gpdb_release']
        node.insert(1, 'trigger', True)


ConcourseTarget = collections.namedtuple('ConcourseTarget', 'name, url')

class Release(object):
  def __init__(self, version, rev, gpdb_environment, secrets_environment, command_runner=None, aws=None, printer=None):
    self.version = version
    self.rev = rev
    self.gpdb_environment = gpdb_environment
    self.secrets_environment = secrets_environment
    self.command_runner = command_runner or CommandRunner()
    self.aws = aws or Aws()
    self.printer = printer or Printer()

    self.release_pipeline = 'gpdb-' + self.version
    self.release_branch = 'release-' + self.version
    self.release_bucket = 'gpdb-%s-concourse' % self.version
    self.release_secrets_file = 'gpdb-%s-ci-secrets.yml' % self.version
    self.pipeline_file = 'ci/concourse/pipelines/pipeline.yml'
    self.concourse_target = ConcourseTarget(name='shared', url='https://shared.ci.eng.pivotal.io')
    self.concourse_team = 'GPDB'

  def check_rev(self):
    return self.command_runner.subprocess_is_successful(
        ('git', 'rev-parse', '--verify', '--quiet', self.rev))

  def create_release_bucket(self):
    bucket = self.aws.get_botobucket(self.release_bucket)
    if not self.aws.bucket_exists(bucket):
      bucket.create(CreateBucketConfiguration={'LocationConstraint': 'us-west-2'})
    return True # failures will be raised as exceptions

  def set_bucket_policy(self):
    bucket = self.aws.get_botobucket(self.release_bucket)
    policy = {
      u'Version': u'2008-10-17',
      u'Statement': [{
        u'Action': [u's3:GetObject', u's3:GetObjectVersion'],
        u'Resource': 'arn:aws:s3:::%s/*' % self.release_bucket,
        u'Effect': u'Allow',
        u'Principal': {u'AWS': 'arn:aws:iam::118837423556:root'} # the `pivotal` data-directors account, into which Pulse Cloud provisions
      }]}
    bucket.Policy().put(Policy=json.dumps(policy))
    return True # failures will be raised as exceptions

  def set_bucket_versioning(self):
    bucket = self.aws.get_botobucket(self.release_bucket)
    bucket.Versioning().enable()
    return True # failures will be raised as exceptions

  def create_release_branch(self):
    commit = self.command_runner.get_subprocess_output(('git', 'show-ref', '-s', 'refs/heads/' + self.release_branch))
    if commit is None:
      return self.command_runner.subprocess_is_successful(('git', 'checkout', '-b', self.release_branch, self.rev))
    rev_sha = self.command_runner.get_subprocess_output(('git', 'rev-parse', '--verify', '--quiet', self.rev))
    if commit == rev_sha:
      return self.command_runner.subprocess_is_successful(('git', 'checkout', self.release_branch))
    self.printer.print_msg("Branch %s exists, but points to a different revision: %s" % (self.release_branch, commit))
    return False

  def tag_branch_point(self): # TODO
    return True

  def _edit_file(self, in_filename, out_filename, replacements):
    """Edit |in_filename|, writing to |out_filename|, while applying the
    edits specified in |replacements|.

    |in_filename| and |out_filename| may be the same file.
    When this method returns, |replacements| will have been modified to contain
    only replacements that were not applied. Each replacement is only applied
    once.

    Args:
      in_filename: string, filename of file to read.
      out_filename: string, filename of file to write.
      replacements: dict, keys are strings to match at the beginning of lines,
          values are the literal replacement lines.
    Returns:
      True iff all replacements were made. If False is returned, replacements
      contains the unapplied replacements. Otherwise, replacements will be
      empty.
    """
    content = []
    with open(in_filename, 'r') as fin:
      for line in fin:
        for key, replacement in replacements.iteritems():
          if line.startswith(key):
            del replacements[key]
            content.append(replacement)
            break
        else:
          content.append(line)
    with open(out_filename, 'w') as fout:
      fout.writelines(content)
    success = not bool(replacements)
    return success

  def edit_getversion_file(self):
    return self._edit_file(
        self.gpdb_environment.path('getversion'),
        self.gpdb_environment.path('getversion'),
        {'GP_VERSION=': 'GP_VERSION=%s\n' % self.version})

  def write_secrets_file(self):
    template_secrets_file = self.secrets_environment.path(SECRETS_FILE_43_STABLE)
    output_secrets_file = self.secrets_environment.path(self.release_secrets_file)
    replacements = {
        'gpdb-git-branch:': 'gpdb-git-branch: %s\n' % self.release_branch,
        'bucket-name:':     'bucket-name: %s\n' % self.release_bucket,
    }
    success = self._edit_file(template_secrets_file, output_secrets_file, replacements)
    if not success:
      os.remove(output_secrets_file)
      self.printer.print_msg('tried to create new secrets file at: ' + output_secrets_file)
      self.printer.print_msg('but unable to find & replace the following keys: ' + ', '.join(replacements.keys()))
    return success

  def edit_pipeline_for_release(self):
    editor = PipelineFileEditor(self.gpdb_environment)
    editor.edit_pipeline_for_release(self.pipeline_file)
    return True

  def fly_ensure_logged_in(self, datetime=datetime.datetime):
    if not self._login_is_valid(datetime=datetime):
      if not self.gpdb_environment.command_runner.subprocess_is_successful(
          ('fly', '-t', self.concourse_target.name, 'login', '-n', self.concourse_team, '-c', self.concourse_target.url)):
        return False

    return self.gpdb_environment.command_runner.subprocess_is_successful(
        ('fly', '-t', self.concourse_target.name, 'sync'))

  def _login_is_valid(self, datetime=datetime.datetime):
    targets = self.gpdb_environment.command_runner.get_subprocess_output(
        ('fly', 'targets', '--print-table-headers'))

    line_iter = iter(targets.splitlines())
    columns = dict(enumerate(next(line_iter).split()))
    for line in line_iter:
      row = dict((columns[i], value) for i, value in enumerate(line.split(None, len(columns) - 1)))
      target = ConcourseTarget(name=row['name'], url=row['url'])

      if target == self.concourse_target:
        return datetime.utcnow() < self._parse_expiry(row['expiry'])
    return False

  @staticmethod
  def _parse_expiry(expiry):
    return datetime.datetime.strptime(expiry, '%a, %d %b %Y %H:%M:%S UTC')

  def fly_set_pipeline(self):
    return self.gpdb_environment.command_runner.subprocess_is_successful(
      ('fly', '-t', self.concourse_target.name, 'set-pipeline', '--non-interactive',
       '-p', self.release_pipeline,
       '-c', self.gpdb_environment.path(self.pipeline_file),
       '-l', self.secrets_environment.path(self.release_secrets_file)))

class Printer(object):
  def print_msg(self, msg):
    print msg


def secrets_dir_is_present(directory):
  return directory.is_dir()


def check_environments(gpdb_environment, secrets_environment, printer=Printer(), aws=Aws()):
  def check_has_43_secrets():
    return secrets_environment.check_has_file(SECRETS_FILE_43_STABLE)

  def check_iam_user():
    return aws.check_iam_user_within_account(SHARED_CONCOURSE_AWS_ACCOUNT_NUMBER)

  checks_to_run = [
      ('overall dependencies', gpdb_environment.check_dependencies),
      ('can git pull in gpdb repo', gpdb_environment.check_git_can_pull),
      ('gpdb repo is clean', gpdb_environment.check_git_status),

      ('can git pull in gpdb-ci-deployments (the secrets repo)', secrets_environment.check_git_can_pull),
      ('gpdb-ci-deployments (the secrets repo) is clean', secrets_environment.check_git_status),
      ('gpdb-ci-deployments (the secrets repo) is up to date', secrets_environment.check_git_head_is_latest),
      ('template secrets file exists', check_has_43_secrets),

      ('AWS IAM user configured and part of correct account (contact the Toolsmiths if you need an account)', check_iam_user)
  ]

  overall_return = True
  failed_checks = []

  for name, check in checks_to_run:
    ret = check()
    if ret:
      printer.print_msg("^^^^ passed check: %s ^^^^" % name)
    else:
      printer.print_msg("^^^^ FAILED check: %s. Output, if any, is above ^^^^\n" % name)
      failed_checks.append(name)
      overall_return = False

  if not overall_return:
    printer.print_msg("\nSummary of failed checks:\n")
    for name in failed_checks:
      printer.print_msg("- %s" % name)

  return overall_return

def exec_step(step, fail_message):
  if not step():
    print fail_message
    sys.exit(4)

def main(argv):
  if len(argv) < 3:
    print "Usage: %s RELEASE_VERSION REVISION" % argv[0]
    return 1

  gpdb_environment = Environment()

  secrets_dir='../gpdb-ci-deployments'
  if not os.path.isdir(secrets_dir):
    print SECRETS_NOT_FOUND_ERROR
    return 2
  secrets_environment = Environment(CommandRunner(cwd=secrets_dir))

  if not check_environments(gpdb_environment, secrets_environment):
    return 2

  version = argv[1]
  rev = argv[2]
  release = Release(version, rev, gpdb_environment, secrets_environment)

  exec_step(release.check_rev,                'Invalid git revision provided: ' + rev)
  exec_step(release.fly_ensure_logged_in,     'Could not log in to Concourse with fly')
  exec_step(release.create_release_bucket,    'Failed to create release bucket in S3')
  exec_step(release.set_bucket_versioning,    'Failed to enable versioning on the S3 bucket')
  exec_step(release.set_bucket_policy,        'Failed to configure the S3 bucket access policy')
  exec_step(release.create_release_branch,    'Failed to create release branch locally with git')
  exec_step(release.tag_branch_point,         'TODO: Failed to tag where we created the branch point')
  exec_step(release.edit_getversion_file,     'Failed to edit the getversion file')
  exec_step(release.write_secrets_file,       'Failed to write pipeline secrets file')
  exec_step(release.edit_pipeline_for_release,'Editing pipeline failed')
  exec_step(release.fly_set_pipeline,         'Failed to set pipeline')
