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

import json
import os
import re
import sys
import subprocess
import boto3
import botocore
from distutils.version import StrictVersion

SECRETS_FILE_43_STABLE = 'gpdb-4.3_STABLE-ci-secrets.yml'

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
  def __init__(self, command_runner=None):
    self.command_runner = command_runner or CommandRunner()

  def check_dependencies(self):
    git_version_output = self.command_runner.get_subprocess_output(
        ('git', '--version'))
    version = git_version_output.split()[2]
    return StrictVersion(version) > StrictVersion('1.9.9')

  def check_git_can_pull(self):
    result = self.command_runner.subprocess_is_successful(
        ('git', 'ls-remote', 'origin', '2>/dev/null'))
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

class Release(object):
  def __init__(self, version, rev, secrets_environment, command_runner=None, aws=None, printer=None):
    self.version = version
    self.rev = rev
    self.release_pipeline = 'gpdb-' + self.version
    self.release_branch = 'release-' + self.version
    self.release_bucket = 'gpdb-%s-concourse' % self.version
    self.secrets_environment = secrets_environment
    self.release_secrets_file = 'gpdb-%s-ci-secrets.yml' % self.version
    self.command_runner = command_runner or CommandRunner()
    self.aws = aws or Aws()
    self.printer = printer or Printer()

  def check_rev(self):
    return self.command_runner.subprocess_is_successful(
        ('git', 'rev-parse', '--verify', '--quiet', self.rev))

  def create_release_bucket(self):
    bucket = self.aws.get_botobucket(self.release_bucket)
    if not self.aws.bucket_exists(bucket):
      bucket.create(CreateBucketConfiguration={'LocationConstraint': 'us-west-2'})

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

  def set_bucket_versioning(self):
    bucket = self.aws.get_botobucket(self.release_bucket)
    bucket.Versioning().enable()

  def create_release_branch(self):
    commit = self.command_runner.get_subprocess_output(('git', 'show-ref', '-s', 'refs/heads/' + self.release_branch))
    if commit is None:
      return self.command_runner.subprocess_is_successful(('git', 'branch', self.release_branch, self.rev))
    rev_sha = self.command_runner.get_subprocess_output(('git', 'rev-parse', '--verify', '--quiet', self.rev))
    if commit == rev_sha:
      return True
    self.printer.print_msg("Branch %s exists, but points to a different revision: %s" % (self.release_branch, commit))
    return False

  def tag_branch_point(self): # TODO
    return True

  def edit_getversion_file(self): # TODO
    return True

  def write_secrets_file(self):
    template_secrets_file = self.secrets_environment.path(SECRETS_FILE_43_STABLE)
    output_secrets_file = self.secrets_environment.path(self.release_secrets_file)
    replacements = {
        'gpdb-git-branch:': 'gpdb-git-branch: %s\n' % self.release_branch,
        'bucket-name:':     'bucket-name: %s\n' % self.release_bucket,
    }
    with open(template_secrets_file, 'r') as fin, open(output_secrets_file, 'w') as fout:
      for line in fin:
        for key, replacement in replacements.iteritems():
          if line.startswith(key):
            del replacements[key]
            fout.write(replacement)
            break
        else:
          fout.write(line)
    success = not bool(replacements)
    if not success:
      os.remove(output_secrets_file)
      self.printer.print_msg('tried to create new secrets file at: ' + output_secrets_file)
      self.printer.print_msg('but unable to find & replace the following keys: ' + ', '.join(replacements.keys()))
    return success


class Printer(object):
  def print_msg(self, msg):
    print msg


def secrets_dir_is_present(directory):
  return directory.is_dir()


def check_environments(gpdb_environment, secrets_environment, printer=Printer()):
  def check_has_43_secrets():
    return secrets_environment.check_has_file(SECRETS_FILE_43_STABLE)

  checks_to_run = [
      ('overall dependencies', gpdb_environment.check_dependencies),
      ('can git pull in gpdb repo', gpdb_environment.check_git_can_pull),
      ('gpdb repo is clean', gpdb_environment.check_git_status),

      ('can git pull in gpdb-ci-deployments (the secrets repo)', secrets_environment.check_git_can_pull),
      ('gpdb-ci-deployments (the secrets repo) is clean', secrets_environment.check_git_status),
      ('gpdb-ci-deployments (the secrets repo) is up to date', secrets_environment.check_git_head_is_latest),
      ('template secrets file exists', check_has_43_secrets)
  ]

  overall_return = True
  failed_checks = []

  for name, check in checks_to_run:
    ret = check()
    if not ret:
      printer.print_msg("^^^^ %s failed; output, if any, is above ^^^^\n" % name)
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
    print 'Please have gpdb-ci-deployments (the secrets repo) as a sibling directory at ' + secrets_dir
    print ''
    print 'Until we parameterize the location of the secrets repo, best to run this from the root of the gpdb repo'
    return 2
  secrets_environment = Environment(CommandRunner(cwd=secrets_dir))

  if not check_environments(gpdb_environment, secrets_environment):
    return 2

  version = argv[1]
  rev = argv[2]
  release = Release(version, rev, secrets_environment)

  exec_step(release.check_rev,                'Invalid git revision provided: ' + rev)
  exec_step(release.create_release_bucket,    'Failed to create release bucket in S3')
  exec_step(release.set_bucket_policy,        'Failed to fully configure the S3 bucket')
  exec_step(release.create_release_branch,    'Failed to create release branch locally with git')
  exec_step(release.tag_branch_point,         'TODO: Failed to tag where we created the branch point')
  exec_step(release.edit_getversion_file,     'TODO: Failed to create release branch locally with git')

  exec_step(release.write_secrets_file,       'Failed to write pipeline secrets file')
