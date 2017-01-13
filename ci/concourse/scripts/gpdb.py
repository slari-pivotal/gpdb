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

import os
import re
import sys
import subprocess
import boto3
import botocore

class Fly(object):

  @staticmethod
  def fly(*args):
    return subprocess.call(('fly', '--target', 'shared') + args)

  def login(self, team):
    return 0 == self.fly('login', '--concourse-url', 'http://shared.ci.eng.pivotal.io', '--team-name', team)

  def set_pipeline(self, pipeline, config, secrets):
    return 0 == self.fly('set-pipeline', '--pipeline', pipeline, '--config', config, '--load-vars-from', secrets, '--non-interactive')

  def unpause_pipeline(self, pipeline):
    return 0 == self.fly('unpause-pipeline', '--pipeline', pipeline)

  def trigger_job(self, pipeline_and_job):
    return 0 == self.fly('trigger-job', '--job', pipeline_and_job)

class AWS(object):

  def __init__(self):
    self.s3 = boto3.resource('s3')

  def get_bucket(self, bucket_name):
    return self.s3.Bucket(bucket_name)

class Git(object):

  @staticmethod
  def get_subprocess_output(cmd):
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    output = p.stdout.read().strip()
    p.stdout.close()
    status = p.wait()
    return output if status == 0 else None

  @staticmethod
  def get_subprocess_result(cmd):
    return 0 == subprocess.call(cmd)

  def verify_revision(self, rev):
    return self.get_subprocess_output(['git', 'rev-parse', '--verify', '--quiet', rev])

  def verify_branch(self, branch):
    return self.get_subprocess_output(['git', 'show-ref', '-s', 'refs/heads/' + branch])

  def verify_tag(self, ref):
    return self.get_subprocess_output(['git', 'show-ref', '-s', 'refs/tags/' + ref])

  def create_branch(self, branch, start_point):
    """Create a branch

    Args:
      branch: string Name of the branch.
      start_point: string Set the branch to this revision.
    Returns:
      True iff the branch was successfully created.
    """
    return self.get_subprocess_output(['git', 'branch', branch, start_point]) is not None

  def create_annotated_tag(self, tag, msg):
    status = subprocess.call(['git', 'tag', '-m', msg, '-a', tag])
    return status == 0

  def get_toplevel(self):
    return self.get_subprocess_output(['git', 'rev-parse', '--show-toplevel'])

  # def commit_and_push(self, msg):
  #   return (self.get_subprocess_result(['git', 'add', '-u']) and
  #           self.get_subprocess_result(['git','commit', '-m', msg]) and
  #           self.get_subprocess_result(['echo', 'git', 'push']))

  def checkout(self, branch):
    return self.get_subprocess_result(['git', 'checkout', branch])

  def add(self, path):
    return self.get_subprocess_result(['git', 'add', path])

  def add_only_tracked_files(self):
    return self.get_subprocess_result(['git', 'add', '-u'])

  def commit(self, msg):
    return self.get_subprocess_result(['git', 'commit', '-m', msg])

  def push(self):
    return self.get_subprocess_result(['echo', 'git', 'push'])

class Release(object):

  def __init__(self, version, rev, gpdb_src, gpdb_deployments_src, git, aws, fly = None):
    self.version = version
    self.rev = rev
    self.rev_sha = git.verify_revision(rev)
    self.release_pipeline = 'gpdb-' + self.version
    self.release_branch = 'release-' + self.version
    self.release_bucket = 'gpdb-%s-concourse' % self.version
    self.release_secrets_file = 'gpdb-%s-ci-secrets.yml' % self.version
    self.git = git
    self.aws = aws
    self.fly = fly
    self.gpdb_src = gpdb_src
    self.gpdb_deployments_src = gpdb_deployments_src

  def create_release_branch(self):
    if not self.rev_sha:
      print >>sys.stderr, "Not a valid revision:", self.rev
      return False
    commit = self.git.verify_branch(self.release_branch)
    if commit is None:
      if not self.git.create_branch(self.release_branch, self.rev_sha):
        return False
    elif commit != self.rev_sha:
      print >>sys.stderr, "Branch %s exists, but points to a different revision: %s" % (self.release_branch, commit)
      return False
    return True

  def tag_branch_point(self):
    tag = self.version + "-rc1"
    if self.git.verify_tag(tag) is None:
      msg = "Tagging version " + self.version
      self.git.create_annotated_tag(tag, msg)
      return True
    return False

    # tag = self.version + "-rc1"
    # tag_sha = self.git.verify_tag(tag)
    # if tag_sha != self.rev_sha:
    #   print >>sys.stderr, "Tag %s exists, but points to a different revision: %s" % (tag, tag_sha)
    #   return False
    # #self.git.create_annotated_tag()
    # if status != 0:
    #   print >>sys.stderr, "Failed to create tag: ", tag
    #   return False
    # return True

  def edit_getversion_file(self):
    with open(os.path.join(self.git.get_toplevel(), 'getversion'), 'r') as f:
      content = f.read()
      content = re.sub(r"^GP_VERSION=.*$", "GP_VERSION=" + self.version, content, flags=re.MULTILINE)
    with open(os.path.join(self.git.get_toplevel(), 'getversion'), 'w') as f:
      f.write(content)
    return True

  def checkout_release_branch(self):
    return self.git.checkout(self.release_branch)

  def commit_and_push(self):
    msg = "Update version to " + self.version
    return self.git.commit_and_push(msg)

  def git_push_getversion(self):
    msg = "Update version to " + self.version
    return (self.git.add_only_tracked_files() and
            self.git.commit(msg) and
            self.git.push())

  def write_secrets_file(self):
    with open(os.path.join(self.git.get_toplevel(), 'gpdb-4.3_STABLE-ci-secrets.yml'), 'r') as f:
      master_contents = f.read()

    release_contents = master_contents
    release_contents = re.sub(r"^gpdb-git-branch:.*$", "gpdb-git-branch: " + self.release_branch, release_contents, flags=re.MULTILINE)
    release_contents = re.sub(r"^bucket-name:.*$", "bucket-name: gpdb-%s-concourse" % self.version, release_contents, flags=re.MULTILINE)

    with open(os.path.join(self.git.get_toplevel(), self.release_secrets_file), 'w') as f:
      f.write(release_contents)

    return True

  def git_push_secrets(self):
    return (self.git.add(self.release_secrets_file) and
            self.git.commit('Add secrets for %s pipeline' % self.version) and
            self.git.push())

  def create_release_bucket(self):
    bucket = self.aws.get_bucket(self.release_bucket)
    if not self.bucket_exists(bucket):
      bucket.create()

  def bucket_exists(self, bucket):
    try:
      bucket.load()
      return True
    except botocore.exceptions.ClientError as e:
      if e.response['Error']['Code'] == '404':
        return False
      raise e

  def init_pipeline(self):
    pipeline_config_path = os.path.join(self.gpdb_src, 'ci/concourse/pipelines/pipeline.yml')
    pipeline_secrets_path = os.path.join(self.gpdb_deployments_src, 'gpdb-%s-ci-secrets.yml' % self.version)
    return (self.fly.login('GPDB') and
            self.fly.set_pipeline(self.release_pipeline, pipeline_config_path, pipeline_secrets_path) and
            self.fly.unpause_pipeline(self.release_pipeline) and
            self.fly.trigger_job(self.release_pipeline + '/bootstrap-ccache'))

def main(argv):
  if len(argv) < 3:
    print "Usage: %s REVISION RELEASE_VERSION" % argv[0]
    return 1

  version = argv[1]
  rev = argv[2]
  git = Git()
  aws = AWS()

  release = Release(version, rev, '.', '../gpdb-ci-deployments', git, aws, fly=Fly())
  if not (
      release.create_release_bucket() and
      release.create_release_branch() and
      release.tag_branch_point() and
      release.checkout_release_branch() and
      release.edit_getversion_file() and
      release.git_push_getversion() and
      os.chdir('../gpdb-ci-deployments') and # FIXME: seems fragile...
      # TODO: rewrite to run secrets file stuff subprocesses with cwd= instead.
      release.write_secrets_file() and
      release.git_push_secrets() and
      release.init_pipeline()
      ):
    return 2

