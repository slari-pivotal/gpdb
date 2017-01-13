from hamcrest import *
import os.path
import shutil
import tempfile
import unittest
import botocore

import gpdb

GETVERSION_TEMPLATE = """\
#!/bin/bash
GP_VERSION=%(version)s

%(tail)s
"""

class MockAWS(object):

  def __init__(self, *buckets):
    self.buckets = buckets

  def get_bucket(self, bucket_name):
    return next((b for b in self.buckets if b.name == bucket_name), None)

class MockBucket(object):

  def __init__(self, name, exists_in_s3 = False):
    self.name = name
    self.was_created = False
    self.exists_in_s3 = exists_in_s3

  def create(self):
    if self.exists_in_s3:
      raise StandardError('MockBucket: already exists: ' + self.name)
    self.was_created = True

  def load(self):
    if not self.exists_in_s3:
      raise botocore.exceptions.ClientError({'Error': {'Code': '404', 'Message': 'NotFound'}}, 'ListBuckets')

class MockFly(object):

  def __init__(self):
    self.last_login_team = None
    self.last_set_pipeline_name = None
    self.last_set_pipeline_config = None
    self.last_set_pipeline_secrets = None
    self.last_unpaused_pipeline = None
    self.last_triggered_job = None

  def login(self, team):
    self.last_login_team = team
    return True

  def set_pipeline(self, pipeline, config, secrets):
    self.last_set_pipeline_name = pipeline
    self.last_set_pipeline_config = config
    self.last_set_pipeline_secrets = secrets
    return True

  def unpause_pipeline(self, pipeline):
    self.last_unpaused_pipeline = pipeline
    return True

  def trigger_job(self, pipeline_and_job):
    self.last_triggered_job = pipeline_and_job
    return True

class MockGit(object):
  def __init__(self):
    self.gitdir = tempfile.mkdtemp()
    self.verify_branch_args = []
    self.create_branch_args = []
    self.create_tag_args = []
    self.valid_revisions = [] # valid and existing revisions
    self.valid_tags = [] # valid and existing tags
    self.current_branch = "4.3_STABLE"
    self.last_added_path = None
    self.add_only_tracked_files_result = None
    self.commit_result = None
    self.push_result = None

  def get_toplevel(self):
    return self.gitdir

  def create_branch(self, branch, start_point):
    self.create_branch_args.append(dict(branch=branch, start_point=start_point))
    return True

  def create_annotated_tag(self, tag, msg):
    self.last_tag_message = msg
    self.create_tag_args.append(tag)
    return True

  def verify_branch(self, branch):
    for elements in self.create_branch_args:
      if elements['branch'] == branch: # we assume the ref is equal to rev_sha saved in self.create_branch_args
        return elements['start_point']
    return None

  def verify_tag(self, tag):
    if tag in self.valid_tags:
      return tag
    return None

  def verify_revision(self,rev):
    if rev in self.valid_revisions:
      return rev
    return None

  def checkout(self, branch):
    self.current_branch = branch
    return self.checkout_result

  def add(self, path):
    self.last_added_path = path
    return True

  def add_only_tracked_files(self):
    return self.add_only_tracked_files_result

  def commit(self, msg):
    self.last_commit_message = msg
    return self.commit_result

  def push(self):
    return self.push_result

  # Utility methods (not part of Git object's interface)

  def tearDown(self):
    shutil.rmtree(self.gitdir, ignore_errors=True)

  def tag_exists(self, tag):
    return tag in self.create_tag_args

  def branch_exists(self, branch, rev_sha):
    for elements in self.create_branch_args:
      if elements['branch'] ==  branch and elements['start_point'] == rev_sha:
        return True
    return False

  def count_branches(self):
    return len(self.create_branch_args)

class ReleaseTest(unittest.TestCase):
  def setUp(self):
    self.git = MockGit()
    self.gpdb_src = self.git.get_toplevel() # temporary
    # self.gpdb_src = tempfile.mkdtemp()
    self.gpdb_deployments_src = tempfile.mkdtemp()

  def tearDown(self):
    self.git.tearDown()

  def newRelease(self, version, commit, git = None, aws = None, fly = None):
    return gpdb.Release(version, commit, self.gpdb_src, self.gpdb_deployments_src, self.git, aws, fly)

  def test_edit_getversion_file(self):
    self.edits_getversion_file("4.3.9.0", "4.3.10.0", "other contents")
    self.edits_getversion_file("4.4.4.3", "4.4.4.4", "more stuff")

  def edits_getversion_file(self, original_version, version, other_contents):
    with open(os.path.join(self.git.get_toplevel(), 'getversion'), 'w') as f:
      f.write(GETVERSION_TEMPLATE % {"version": original_version, "tail": other_contents})

    release = self.newRelease(version, '123abc')
    result = release.edit_getversion_file()

    assert_that(result, equal_to(True))

    with open(os.path.join(self.git.get_toplevel(), 'getversion'), 'r') as f:
      edited_getversion_contents = f.read()
    assert_that(edited_getversion_contents, equal_to(GETVERSION_TEMPLATE % {"version": version, "tail": other_contents}))

  def test_create_release_branch_when_branch_doesnt_exist(self):
    self.setup_existing_revisions('123abc')
    # When the branch does not exist yet, it creates the branch
    release = self.newRelease('4.3.10.0', '123abc')

    assert_that(self.git.count_branches(), equal_to(0))
    result = release.create_release_branch()
    assert_that(result, equal_to(True))

  def test_create_release_branch_when_branch_exist(self):
    self.setup_existing_revisions('123abc')
    # When the branch already exists with the correct commit, it returns true
    self.setup_existing_branch('release-4.3.10.0', '123abc')
    release = self.newRelease('4.3.10.0', '123abc')

    assert_that(self.git.count_branches(), equal_to(1))
    result = release.create_release_branch()
    assert_that(result, equal_to(True))
    assert_that(self.git.branch_exists('release-4.3.10.0', '123abc'))
    assert_that(self.git.count_branches(), equal_to(1))

  def test_create_release_branch_when_rev_sha_is_bogus(self):
    self.setup_existing_revisions('123abc')
    release = self.newRelease("4.3.10.0", 'some-non-existent-sha')

    assert_that(self.git.count_branches(), equal_to(0))
    result = release.create_release_branch()
    assert_that(result, equal_to(False))
    assert_that(self.git.count_branches(), equal_to(0))

  def test_tag_branch_point_mentions_version_in_message(self):
    self.setup_existing_revisions('123abc')
    release = self.newRelease('4.3.10.0', '123abc')

    result = release.tag_branch_point()
    assert_that(result, equal_to(True))
    assert_that(self.git.tag_exists('4.3.10.0-rc1'))
    assert_that(self.git.last_tag_message, contains_string('4.3.10.0'))

  def test_tag_branch_point_when_tag_already_exists(self):
    self.setup_existing_tag('4.3.10.0-rc1')
    release = self.newRelease('4.3.10.0', '123abc')

    result = release.tag_branch_point()
    assert_that(result, equal_to(False))

  def test_tag_branch_point_when_tag_already_exists_but_is_not_valid(self):
    pass

  def test_git_push_getversion_mentions_version_in_message(self):
    self.setup_successful_git_commit()
    self.git.push_result = True
    self.git.add_only_tracked_files_result = True
    release = self.newRelease('4.3.10.0', '123abc')

    result = release.git_push_getversion()
    assert_that(result, equal_to(True))
    assert_that(self.git.last_commit_message, contains_string('4.3.10.0'))

  def test_git_push_getversion_fails_when_git_add_fails(self):
    self.setup_successful_git_commit()
    self.git.push_result = True
    self.git.add_only_tracked_files_result = False
    release = self.newRelease('4.3.10.0', '123abc')

    result = release.git_push_getversion()
    assert_that(result, equal_to(False))

  def test_git_push_getversion_fails_when_push_fails(self):
    self.setup_successful_git_commit()
    self.git.push_result = False
    self.git.add_only_tracked_files_result = True
    release = self.newRelease('4.3.10.0', '123abc')

    result = release.git_push_getversion()
    assert_that(result, equal_to(False))

  def test_checkout_release_branch(self):
    self.setup_successful_git_checkout()
    release = self.newRelease('4.3.10.0', '123abc')

    result = release.checkout_release_branch()
    assert_that(result, equal_to(True))
    assert_that(self.git.current_branch, equal_to('release-4.3.10.0'))

  def test_checkout_release_branch_fails(self):
    self.setup_failing_git_checkout()
    release = self.newRelease('4.3.10.0', '123abc')

    result = release.checkout_release_branch()
    assert_that(result, equal_to(False))

  def test_write_secrets_file(self):
    self.setup_master_secrets_file()
    release = self.newRelease('4.3.10.0', '123abc')
    result = release.write_secrets_file()

    assert_that(result, equal_to(True))
    assert_that(os.path.isfile(self.secrets_file_path()))
    assert_that(self.secrets_file_contents(), contains_string('gpdb-git-branch: release-4.3.10.0'))
    assert_that(self.secrets_file_contents(), contains_string('bucket-name: gpdb-4.3.10.0-concourse'))

  def test_git_push_secrets_mentions_version_in_message(self):
    self.setup_successful_git_commit()
    self.git.push_result = True
    release = self.newRelease('4.3.10.0', '123abc')
    result = release.git_push_secrets()

    assert_that(result, equal_to(True))
    assert_that(self.git.last_added_path, equal_to('gpdb-4.3.10.0-ci-secrets.yml'))
    assert_that(self.git.last_commit_message, contains_string('4.3.10.0'))

  def test_git_push_secrets_fails_when_push_fails(self):
    self.setup_successful_git_commit()
    self.git.push_result = False
    release = self.newRelease('4.3.10.0', '123abc')
    result = release.git_push_secrets()

    assert_that(result, equal_to(False))

  def test_create_release_bucket(self):
    bucket = MockBucket('gpdb-4.3.10.0-concourse')
    aws = MockAWS(bucket)
    release = self.newRelease('4.3.10.0', '123abc', aws=aws)

    release.create_release_bucket()
    assert_that(bucket.was_created, equal_to(True))

  def test_create_release_bucket_when_exists_in_s3_does_not_call_create(self):
    bucket = MockBucket('gpdb-4.3.10.0-concourse', exists_in_s3 = True)
    aws = MockAWS(bucket)
    release = self.newRelease('4.3.10.0', '123abc', aws=aws)

    release.create_release_bucket()
    assert_that(bucket.was_created, equal_to(False))

  def test_init_pipeline(self):
    fly = MockFly()
    release = self.newRelease('4.3.10.0', '123abc', fly=fly)

    release.init_pipeline()
    assert_that(fly.last_login_team, equal_to('GPDB'))
    assert_that(fly.last_set_pipeline_name, equal_to('gpdb-4.3.10.0'))
    assert_that(fly.last_set_pipeline_config, equal_to(os.path.join(self.gpdb_src, 'ci/concourse/pipelines/pipeline.yml')))
    assert_that(fly.last_set_pipeline_secrets, equal_to(os.path.join(self.gpdb_deployments_src, 'gpdb-4.3.10.0-ci-secrets.yml')))
    assert_that(fly.last_unpaused_pipeline, equal_to('gpdb-4.3.10.0'))
    assert_that(fly.last_triggered_job, equal_to('gpdb-4.3.10.0/bootstrap-ccache'))

  ## utility methods

  def setup_master_secrets_file(self):
    with open(os.path.join(self.git.get_toplevel(), 'gpdb-4.3_STABLE-ci-secrets.yml'), 'w') as f:
      f.write(
        'gpdb-git-branch:4.3_STABLE\n' +
        'bucket-name: gpdb-4.3-stable-concourse\n'
      )

  def secrets_file_path(self):
    return os.path.join(self.git.get_toplevel(), 'gpdb-4.3.10.0-ci-secrets.yml')

  def secrets_file_contents(self):
    with open(self.secrets_file_path(), 'r') as f:
      return f.read()

  def setup_successful_git_checkout(self):
    self.git.checkout_result = True

  def setup_failing_git_checkout(self):
    self.git.checkout_result = False

  def setup_successful_git_commit(self):
    self.git.commit_result = True

  def setup_failing_git_commit(self):
    self.git.commit_result = False

  def setup_existing_revisions(self, *revisions):
    self.git.valid_revisions = revisions[:]

  def setup_existing_branch(self, branch, start_point):
    self.git.create_branch(branch, start_point)

  def setup_existing_tag(self, tag):
    self.git.valid_tags.append(tag)
    self.git.create_annotated_tag(tag, "msg")

if __name__ == '__main__':
    unittest.main()
