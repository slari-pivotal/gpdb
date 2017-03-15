import collections
import datetime
import errno
from hamcrest import *
import json
import os.path
import shutil
import tempfile
import unittest

import release
from release import Environment


class Error(Exception):
  pass


class Spy(object):
  def __init__(self, returns=None):
    self.calls = 0
    self.returns = returns
  def __call__(self, *args, **kwargs):
    self.last_args = args
    self.last_kwargs = kwargs
    self.calls += 1
    return self.returns


class MockPrinter(object):
  def print_msg(self, msg):
    pass


class MockCommandRunner(object):

  CommandResponse = collections.namedtuple('CommandResponse', 'output, exit_code, allowed, exists')

  def __init__(self, cwd=None):
    self.cwd = cwd
    self.branch_changed = False
    self.subprocess_mock_outputs = {}

  def respond_to_command_with(self, cmd, output=None, exit_code=0, allowed=True, branch_changed=False, exists=True):
    self.subprocess_mock_outputs[cmd] = self.CommandResponse(output, exit_code, allowed, exists)
    self.branch_changed |= branch_changed

  def get_subprocess_output(self, cmd):
    return self._get_response(cmd).output

  def subprocess_is_successful(self, cmd):
    return 0 == self._get_response(cmd).exit_code

  def _get_response(self, cmd):
    response = self.subprocess_mock_outputs[cmd]
    if not response.allowed:
      raise AssertionError('Command is not allowed to be called: ' + str(cmd))
    if not response.exists:
      raise OSError(errno.ENOENT, 'No such file or directory: ' + str(cmd))
    return response


class EnvironmentTest(unittest.TestCase):
  class MockCommandRunner(MockCommandRunner):
    def __init__(self, cwd='/proper/git/directory'):
      super(EnvironmentTest.MockCommandRunner, self).__init__(cwd)
      self.respond_to_command_with(
          ('git', '--version'), output='git version 2.10.2')
      self.respond_to_command_with(
          ('fly', '--version'), output='2.6.0')
      self.respond_to_command_with(
          ('pip', 'install', '-r', 'ci/release/requirements.txt'), exit_code=0)
      self.respond_to_command_with(
          ('git', 'status', '--porcelain'), output='')
      self.respond_to_command_with(
          ('git', 'rev-parse', '--show-toplevel'), output='/proper/git/directory')
      self.respond_to_command_with(
          ('git', 'ls-remote', 'origin', 'master'), output='abc123def456a78912323434\trefs/heads/master')
      self.respond_to_command_with(
          ('git', 'rev-parse', 'HEAD'), output='abc123def456a78912323434')
      self.respond_to_command_with(
          ('git', 'ls-remote', 'origin', 'refs/connectivity-test'), exit_code=0)

  def test_check_dependencies(self):
    environment = Environment(command_runner=self.MockCommandRunner())
    result = environment.check_dependencies()
    assert_that(result)

  def test_check_dependencies_when_git_too_old(self):
    command_runner = self.MockCommandRunner()
    command_runner.respond_to_command_with(
        ('git', '--version'), output='git version 1.7.0')

    environment = Environment(command_runner=command_runner)
    result = environment.check_dependencies()
    assert_that(result, equal_to(False))

  def test_check_dependencies_when_fly_too_old(self):
    command_runner = self.MockCommandRunner()
    command_runner.respond_to_command_with(
        ('fly', '--version'), output='2.5.999')

    environment = Environment(command_runner=command_runner)
    result = environment.check_dependencies()
    assert_that(result, equal_to(False))

  def test_check_fly_exists(self):
    command_runner = self.MockCommandRunner()
    command_runner.respond_to_command_with(
        ('fly', '--version'), exists=False)

    environment = Environment(command_runner=command_runner, printer=MockPrinter())
    result = environment.check_dependencies()
    assert_that(result, equal_to(False))

  def test_chek_dependencies_when_pip_fails(self):
    command_runner = self.MockCommandRunner()
    command_runner.respond_to_command_with(
          ('pip', 'install', '-r', 'ci/release/requirements.txt'), exit_code=1)

    environment = Environment(command_runner=command_runner)
    result = environment.check_dependencies()
    assert_that(result, equal_to(False))

  def test_check_git_can_pull(self):
    environment = Environment(command_runner=self.MockCommandRunner())
    result = environment.check_git_can_pull()
    assert_that(result)

  def test_check_git_can_pull_fails(self):
    command_runner = self.MockCommandRunner()
    command_runner.respond_to_command_with(
        ('git', 'ls-remote', 'origin', 'refs/connectivity-test'), exit_code=128)

    environment = Environment(command_runner=command_runner)
    result = environment.check_git_can_pull()
    assert_that(result, equal_to(False))

  def test_check_git_status(self):
    environment = Environment(command_runner=self.MockCommandRunner())
    result = environment.check_git_status()
    assert_that(result)

  def test_check_git_status_cwd_can_be_relative_path(self):
    current_working_directory = os.getcwd() # we're relying on the real OS for this test. Maybe better to inject something?
    cwd_sibling_relative_path = '../sibling_dir'
    cwd_sibling_absolute_path = os.path.abspath(os.path.join(current_working_directory, cwd_sibling_relative_path))
    command_runner = self.MockCommandRunner(cwd=cwd_sibling_relative_path)
    command_runner.respond_to_command_with(
        ('git', 'rev-parse', '--show-toplevel'), output=cwd_sibling_absolute_path)

    environment = Environment(command_runner=command_runner)
    result = environment.check_git_status()
    assert_that(result)

  def test_check_git_status_not_a_git_repo(self):
    command_runner = self.MockCommandRunner(cwd='/not/a/git/dir')
    command_runner.respond_to_command_with(
        ('git', 'rev-parse', '--show-toplevel'), output=None)

    environment = Environment(command_runner=command_runner)
    result = environment.check_git_status()
    assert_that(result, equal_to(False))

  def test_check_git_status_not_at_root_of_git_repo(self):
    command_runner = self.MockCommandRunner(cwd='/proper/git/directory/too/far/down')
    command_runner.respond_to_command_with(
        ('git', 'rev-parse', '--show-toplevel'), output='/proper/git/directory')

    environment = Environment(command_runner=command_runner)
    result = environment.check_git_status()
    assert_that(result, equal_to(False))

  def test_check_git_status_dirty(self):
    command_runner = self.MockCommandRunner()
    command_runner.respond_to_command_with(
        ('git', 'status', '--porcelain'), output='M commit_me.py')

    environment = Environment(command_runner=command_runner)
    result = environment.check_git_status()
    assert_that(result, equal_to(False))

  def test_check_git_head_is_latest(self):
    command_runner = self.MockCommandRunner()

    environment = Environment(command_runner=command_runner)
    result = environment.check_git_head_is_latest()
    assert_that(result)

  def test_check_git_head_is_not_latest(self):
    command_runner = self.MockCommandRunner()
    command_runner.respond_to_command_with(
        ('git', 'ls-remote', 'origin', 'master'), output='add123456\trefs/heads/master')
    command_runner.respond_to_command_with(
        ('git', 'rev-parse', 'HEAD'), output='bad987764')

    environment = Environment(command_runner=command_runner)
    result = environment.check_git_head_is_latest()
    assert_that(result, equal_to(False))

  def test_check_git_remote_not_authorized(self):
    command_runner = self.MockCommandRunner()
    command_runner.respond_to_command_with(
        ('git', 'ls-remote', 'origin', 'master'), output=None)
    command_runner.respond_to_command_with(
        ('git', 'rev-parse', 'HEAD'), output='bad987764')

    environment = Environment(command_runner=command_runner)
    result = environment.check_git_head_is_latest()
    assert_that(result, equal_to(False))

  def test_check_has_file(self):
    existing_files = set([
        '/proper/git/directory/file/in_repo',
        '/proper/git/directory/another_file',
        '/outside/outside_file',
    ])
    def exists(path):
      return path in existing_files
    environment = Environment(command_runner=self.MockCommandRunner())
    assert_that(environment.check_has_file('file/in_repo', os_path_exists=exists), equal_to(True))
    assert_that(environment.check_has_file('another_file', os_path_exists=exists), equal_to(True))
    assert_that(environment.check_has_file('file_not_in_repo', os_path_exists=exists), equal_to(False))
    assert_that(environment.check_has_file('outside_file', os_path_exists=exists), equal_to(False))


class ReleaseTestBase(unittest.TestCase):
  class MockAws(object):
    class Bucket(object):
      class MockPolicy(object):
        def __init__(self):
          self.policy_json = None
        def put(self, Policy=None):
          self.policy_json = Policy

      class MockVersioning(object):
        def __init__(self):
          self.status = None
        def enable(self):
          self.status = 'Enabled'

      def __init__(self, name, exists_in_s3=False):
        self.name = name
        self.was_created = False
        self.exists_in_s3 = exists_in_s3
        self.bucket_policy = self.MockPolicy()
        self.bucket_versioning = self.MockVersioning()

      def create(self, **kwargs):
        self.region = kwargs.get('CreateBucketConfiguration', {}).get('LocationConstraint')
        if self.exists_in_s3:
          raise StandardError('MockAws.Bucket: already exists: ' + self.name)
        self.was_created = True

      def Policy(self):
        return self.bucket_policy

      def Versioning(self):
        return self.bucket_versioning

    def __init__(self, *buckets):
      self.buckets = buckets

    def get_botobucket(self, bucket_name):
      return next((b for b in self.buckets if b.name == bucket_name), None)

    def bucket_exists(self, bucket):
      return bucket.exists_in_s3


class ReleaseTest(ReleaseTestBase):
  def test_check_rev(self):
    command_runner = MockCommandRunner()
    command_runner.respond_to_command_with(
        ('git', 'rev-parse', '--verify', '--quiet', 'HEAD'), exit_code=0)
    release_with_good_rev = release.Release('1.2.3', 'HEAD', gpdb_environment=None, secrets_environment=None, command_runner=command_runner, aws=self.MockAws())
    assert_that(release_with_good_rev.check_rev())

  def test_check_bad_rev(self):
    command_runner = MockCommandRunner()
    command_runner.respond_to_command_with(
          ('git', 'rev-parse', '--verify', '--quiet', 'DEADBEEF'), exit_code=1)

    release_with_bad_rev = release.Release('1.2.3', 'DEADBEEF', gpdb_environment=None, secrets_environment=None, command_runner=command_runner, aws=self.MockAws())
    assert_that(release_with_bad_rev.check_rev(), equal_to(False))

  def test_create_release_bucket(self):
    bucket = self.MockAws.Bucket('gpdb-4.3.10.0-concourse')
    aws = self.MockAws(bucket)
    release_with_good_aws = release.Release('4.3.10.0', '123abc', gpdb_environment=None, secrets_environment=None, aws=aws)

    command_return = release_with_good_aws.create_release_bucket()
    assert_that(command_return, equal_to(True))
    assert_that(bucket.was_created, equal_to(True))
    assert_that(bucket.region, equal_to('us-west-2'))

  def test_create_release_bucket_when_exists_in_s3_does_not_call_create(self):
    bucket_already_there = self.MockAws.Bucket('gpdb-4.3.10.0-concourse', exists_in_s3 = True)
    aws = self.MockAws(bucket_already_there)
    release_with_bucket_already_there = release.Release('4.3.10.0', '123abc', gpdb_environment=None, secrets_environment=None, aws=aws)

    command_return = release_with_bucket_already_there.create_release_bucket()
    assert_that(command_return, equal_to(True))
    assert_that(bucket_already_there.was_created, equal_to(False))

  def test_set_bucket_policy(self):
    bucket = self.MockAws.Bucket('gpdb-4.3.10.0-concourse', exists_in_s3 = True)
    aws = self.MockAws(bucket)
    release_with_aws = release.Release('4.3.10.0', '123abc', gpdb_environment=None, secrets_environment=None, aws=aws)

    assert_that(release_with_aws.set_bucket_policy())
    policy = json.loads(bucket.bucket_policy.policy_json)
    expected_policy = self.aws_policy('arn:aws:s3:::gpdb-4.3.10.0-concourse/*', 'arn:aws:iam::118837423556:root')
    assert_that(policy, equal_to(expected_policy))

  def aws_policy(self, resource, principal):
    return {
      u'Version': u'2008-10-17',
      u'Statement': [{
        u'Action': [u's3:GetObject', u's3:GetObjectVersion'],
        u'Resource': resource,
        u'Effect': u'Allow',
        u'Principal': {u'AWS': principal}
      }]}

  def test_set_bucket_versioning(self):
    bucket = self.MockAws.Bucket('gpdb-4.3.10.0-concourse', exists_in_s3 = True)
    aws = self.MockAws(bucket)
    release_with_aws = release.Release('4.3.10.0', '123abc', gpdb_environment=None, secrets_environment=None, aws=aws)

    assert_that(release_with_aws.set_bucket_versioning())
    assert_that(bucket.bucket_versioning.status, equal_to('Enabled'))

  def test_create_release_branch_when_branch_doesnt_exist(self):
    command_runner = MockCommandRunner()
    command_runner.respond_to_command_with(
        ('git', 'show-ref', '-s', 'refs/heads/release-4.3.25.3'), output=None, exit_code=1)
    command_runner.respond_to_command_with(
        ('git', 'checkout', '-b', 'release-4.3.25.3', '123abc'), exit_code=0, branch_changed=True)

    release_making_branch = release.Release('4.3.25.3', '123abc', gpdb_environment=None, secrets_environment=None, command_runner=command_runner, printer=MockPrinter(), aws=self.MockAws())
    result = release_making_branch.create_release_branch()
    assert_that(result, equal_to(True))
    assert_that(command_runner.branch_changed, equal_to(True))

  def test_create_release_branch_when_branch_exists_and_is_different(self):
    command_runner = MockCommandRunner()
    command_runner.respond_to_command_with(
        ('git', 'rev-parse', '--verify', '--quiet', '123abc'), output='123abc456deadbeef')
    command_runner.respond_to_command_with(
        ('git', 'checkout', '-b', 'release-4.3.25.3', '123abc'), allowed=False)
    command_runner.respond_to_command_with(
        ('git', 'checkout', 'release-4.3.25.3'), allowed=False)
    command_runner.respond_to_command_with(
        ('git', 'show-ref', '-s', 'refs/heads/release-4.3.25.3'), output='sha-other-than-123abc', exit_code=0)

    release_making_branch = release.Release('4.3.25.3', '123abc', gpdb_environment=None, secrets_environment=None, command_runner=command_runner, printer=MockPrinter(), aws=self.MockAws())
    result = release_making_branch.create_release_branch()
    assert_that(result, equal_to(False))
    assert_that(command_runner.branch_changed, equal_to(False))

  def test_create_release_branch_when_branch_exists_and_is_same(self):
    command_runner = MockCommandRunner()
    command_runner.respond_to_command_with(
        ('git', 'rev-parse', '--verify', '--quiet', '123abc'), output='123abc456deadbeef')
    command_runner.respond_to_command_with(
        ('git', 'checkout', '-b', 'release-4.3.25.3', '123abc'), allowed=False)
    command_runner.respond_to_command_with(
        ('git', 'checkout', 'release-4.3.25.3'), exit_code=0, branch_changed=True)
    command_runner.respond_to_command_with(
        ('git', 'show-ref', '-s', 'refs/heads/release-4.3.25.3'), output='123abc456deadbeef', exit_code=0)

    release_making_branch = release.Release('4.3.25.3', '123abc', gpdb_environment=None, secrets_environment=None, command_runner=command_runner, printer=MockPrinter(), aws=self.MockAws())
    result = release_making_branch.create_release_branch()
    assert_that(result, equal_to(True))
    assert_that(command_runner.branch_changed, equal_to(True))

  def test_tag_branch_point(self):
    release_for_tagging = release.Release('4.3.25.3', '123abc', gpdb_environment=None, secrets_environment=None, aws=self.MockAws())
    assert_that(release_for_tagging.tag_branch_point())


class FakeEnvironment(object):
  def __init__(self, directory, command_runner=None):
    self.directory = directory
    self.command_runner = command_runner
    if self.command_runner:
      self.command_runner.cwd = directory

  def path(self, *path_segments):
    return os.path.join(self.directory, *path_segments)


GETVERSION_TEMPLATE = """\
#!/bin/bash
GP_VERSION=%(version)s

%(tail)s
"""


PIPELINE_STARTING_CONTENTS = """\
jobs:
- name: pulse_ON_aNightlyTrigger
  plan:
  - get: pulse-api-image
  - get: nightly-trigger-pulse
    gpdb_release: delete
    trigger: true
  - aggregate:
    - get: gpdb_src
      gpdb_release: add_trigger
      params: {}
      passed: []

# resources group comment
resources:
- name: seecrits
  type: git
  source:
    repository: {{seecrits-repository}}
    password: {{seecrits-password}}
- name: nest_fetcher
  source:
    gulls:
      sea: squak
      gpdb_release: delete
    hawks:
      sea: richard_sherman   # go niners
# These go last to catch edit-in-place bugs.
- name: chivalrous   # you know... "knightly"
  gpdb_release: delete
  type: time
  source:
    location: Camelot # a place I'd like to go
    time: '5:15'
- name: fortnightly
  gpdb_release: delete
  type: time
  source:
    location: Aqaba # a place I'd like to go
    time: '5:15'

groups:
- name: all
  jobs:
  - first
  - second
  - 'gpdb_release: delete'
  - fourth
"""


EXPECTED_CHANGED_PIPELINE = """\
jobs:
- name: pulse_ON_aNightlyTrigger
  plan:
  - get: pulse-api-image
  - aggregate:
    - get: gpdb_src
      trigger: true
      params: {}
      passed: []

# resources group comment
resources:
- name: seecrits
  type: git
  source:
    repository: {{seecrits-repository}}
    password: {{seecrits-password}}
- name: nest_fetcher
  source:
    hawks:
      sea: richard_sherman   # go niners

groups:
- name: all
  jobs:
  - first
  - second
  - 'gpdb_release: delete'
  - fourth
"""


class ReleaseTest_GpdbDirectory(ReleaseTestBase):
  def setUp(self):
    self.gpdb_environment = FakeEnvironment(tempfile.mkdtemp())
    os.makedirs(self.gpdb_environment.path('ci', 'concourse', 'pipelines'))

    self.aws = self.MockAws()

  def tearDown(self):
    shutil.rmtree(self.gpdb_environment.directory)

  def test_edit_getversion_file(self):
    self.edits_getversion_file("4.3.9.0", "4.3.10.0", "other contents")
    self.edits_getversion_file("4.4.4.3", "4.4.4.4", "more stuff")

  def edits_getversion_file(self, original_version, version, other_contents):
    with open(self.gpdb_environment.path('getversion'), 'w') as f:
      f.write(GETVERSION_TEMPLATE % {"version": original_version, "tail": other_contents})

    release_edit_getversion = release.Release(version, '123abc', self.gpdb_environment, secrets_environment=None, aws=self.aws)
    assert_that(release_edit_getversion.edit_getversion_file())

    with open(self.gpdb_environment.path('getversion'), 'r') as f:
      edited_getversion_contents = f.read()
    assert_that(edited_getversion_contents, equal_to(GETVERSION_TEMPLATE % {"version": version, "tail": other_contents}))

  def test_edit_getversion_file_no_GP_VERSION_to_edit(self):
    with open(self.gpdb_environment.path('getversion'), 'w') as f:
      f.write('nothing to see here\nmove along\nmove along\n')

    release_edit_getversion = release.Release('4.3.12.12', '123abc', self.gpdb_environment, secrets_environment=None, aws=self.aws)
    assert_that(release_edit_getversion.edit_getversion_file(), equal_to(False))
    with open(self.gpdb_environment.path('getversion'), 'r') as f:
      edited_getversion_contents = f.read()
    assert_that(edited_getversion_contents, equal_to('nothing to see here\nmove along\nmove along\n'))

  def test_edit_pipeline_for_release(self):
    with open(self.gpdb_environment.path('ci/concourse/pipelines/pipeline.yml'), 'w') as f:
      f.write(PIPELINE_STARTING_CONTENTS)
    release_pipeline_changer = release.Release('4.3.1.1', '321cab', self.gpdb_environment, secrets_environment=None, aws=self.aws)
    assert_that(release_pipeline_changer.edit_pipeline_for_release())
    with open(self.gpdb_environment.path('ci/concourse/pipelines/pipeline.yml'), 'r') as f:
      assert_that(f.read(), equal_to(EXPECTED_CHANGED_PIPELINE))


class ReleaseTest_SecretsDirectory(ReleaseTestBase):
  def setUp(self):
    self.secrets_environment = FakeEnvironment(tempfile.mkdtemp())
    self.aws = self.MockAws()

  def tearDown(self):
    shutil.rmtree(self.secrets_environment.directory)

  def test_write_secrets_file(self):
    with open(self.secrets_environment.path('gpdb-4.3_STABLE-ci-secrets.yml'), 'w') as fout:
      fout.writelines(x + '\n' for x in [
        'another-key: with-a-value',
        'gpdb-git-branch:4.3_STABLE',
        'gpdb-git-key: |',
        '  -----BEGIN KEY-----',
        '  base64key==',
        '  -----END KEY-----',
        'bucket-name: gpdb-4.3-stable-concourse'
      ])
    release_secrets_file = release.Release('4.3.25.3', '123abc', gpdb_environment=None, secrets_environment=self.secrets_environment, aws=self.aws)

    assert_that(release_secrets_file.write_secrets_file())

    assert_that(os.path.isfile(self.secrets_environment.path('gpdb-4.3.25.3-ci-secrets.yml')))
    with open(self.secrets_environment.path('gpdb-4.3.25.3-ci-secrets.yml'), 'r') as f:
      contents = f.readlines()
      assert_that(contents, has_length(7))
      assert_that(contents, has_items(
        'another-key: with-a-value\n',
        'gpdb-git-branch: release-4.3.25.3\n',
        'bucket-name: gpdb-4.3.25.3-concourse\n'))

  def test_write_secrets_file_alert_missing_key_branch(self):
    with open(self.secrets_environment.path('gpdb-4.3_STABLE-ci-secrets.yml'), 'w') as fout:
      fout.writelines(x + '\n' for x in [
        'pgdb-bat-grinch:4.3_STABLE',
        'bucket-name: gpdb-4.3-stable-concourse'
      ])
    release_secrets_file = release.Release('4.3.25.8', '123abc', gpdb_environment=None, secrets_environment=self.secrets_environment, aws=self.aws, printer=MockPrinter())

    assert_that(release_secrets_file.write_secrets_file(), equal_to(False))
    assert_that(os.path.isfile(self.secrets_environment.path('gpdb-4.3.25.8-ci-secrets.yml')), equal_to(False))

  def test_write_secrets_file_alert_gnarly_template(self):
    with open(self.secrets_environment.path('gpdb-4.3_STABLE-ci-secrets.yml'), 'w') as fout:
      fout.writelines(x + '\n' for x in [
        'bucket-name: "gpdb-git-branch:"',
        'gpdb-git-branch: ewfoiwevo',
      ])
    release_secrets_file = release.Release('4.3.25.8', '123abc', gpdb_environment=None, secrets_environment=self.secrets_environment, aws=self.aws, printer=MockPrinter())

    assert_that(release_secrets_file.write_secrets_file())
    assert_that(os.path.isfile(self.secrets_environment.path('gpdb-4.3.25.8-ci-secrets.yml')))


class ReleaseTest_Fly(ReleaseTestBase):
  class MockDatetime(object):
    def __init__(self, fake_utcnow):
      self.fake_utcnow = fake_utcnow

    def utcnow(self):
      return self.fake_utcnow

  def setUp(self):
    self.gpdb_environment = FakeEnvironment(tempfile.mkdtemp(), command_runner=MockCommandRunner())
    os.makedirs(self.gpdb_environment.path('ci', 'concourse', 'pipelines'))
    self.secrets_environment = FakeEnvironment(tempfile.mkdtemp())
    targets_output = (
        "name     url                                  team      expiry\n"
        "sharded  https://shared.ci.eng.pivotal.io     main      Thu, 26 Jan 2217 22:47:46 UTC\n"
        "shared   http://not-shared.ci.eng.pivotal.io  not-main  Thu, 26 Jan 2217 22:47:46 UTC\n"
        "shared   https://shared.ci.eng.pivotal.io     gpdb      Thu, 26 Jan 2017 22:47:46 UTC\n"
    )
    self.just_before_expiry = datetime.datetime(2017, 1, 26, 22, 47, 45, 999999)
    self.after_expiry = datetime.datetime(2018, 1, 26, 22, 47, 45, 999999)
    self.gpdb_environment.command_runner.respond_to_command_with(
        ('fly', 'targets', '--print-table-headers'), output=targets_output)
    self.gpdb_environment.command_runner.respond_to_command_with(
        ('fly', '-t', 'shared', 'sync'), exit_code=0)

    self.aws = self.MockAws()

  def tearDown(self):
    shutil.rmtree(self.gpdb_environment.directory)
    shutil.rmtree(self.secrets_environment.directory)

  def test_fly_ensure_logged_in_expired(self):
    mock_datetime = self.MockDatetime(self.after_expiry)
    self.gpdb_environment.command_runner.respond_to_command_with(
        ('fly', '-t', 'shared', 'login', '-n', 'GPDB', '-c', 'https://shared.ci.eng.pivotal.io'), exit_code=0)
    release_fly = release.Release('4.3.27.7', 'cab234', self.gpdb_environment, secrets_environment=None, aws=self.aws)
    assert_that(release_fly.fly_ensure_logged_in(datetime=mock_datetime))

  def test_fly_ensure_logged_in_already(self):
    mock_datetime = self.MockDatetime(self.just_before_expiry)
    self.gpdb_environment.command_runner.respond_to_command_with(
        ('fly', '-t', 'shared', 'login', '-n', 'GPDB', '-c', 'https://shared.ci.eng.pivotal.io'), allowed=False)
    release_fly = release.Release('4.3.27.7', 'cab234', self.gpdb_environment, secrets_environment=None, aws=self.aws)
    assert_that(release_fly.fly_ensure_logged_in(datetime=mock_datetime))

  def test_fly_ensure_logged_in_fly_errors(self):
    mock_datetime = self.MockDatetime(self.after_expiry)
    self.gpdb_environment.command_runner.respond_to_command_with(
        ('fly', '-t', 'shared', 'login', '-n', 'GPDB', '-c', 'https://shared.ci.eng.pivotal.io'), exit_code=1)
    self.gpdb_environment.command_runner.respond_to_command_with(
        ('fly', '-t', 'shared', 'sync'), allowed=False)
    release_fly = release.Release('4.3.27.7', 'cab234', self.gpdb_environment, secrets_environment=None, aws=self.aws)
    assert_that(release_fly.fly_ensure_logged_in(datetime=mock_datetime), equal_to(False))

  def test_fly_ensure_logged_in_calls_fly_sync_if_logged_in(self):
    mock_datetime = self.MockDatetime(self.just_before_expiry)
    self.gpdb_environment.command_runner.respond_to_command_with(
        ('fly', '-t', 'shared', 'login', '-n', 'GPDB', '-c', 'https://shared.ci.eng.pivotal.io'), allowed=False)
    self.gpdb_environment.command_runner.respond_to_command_with(
        ('fly', '-t', 'shared', 'sync'), exit_code=1)
    release_fly = release.Release('4.3.27.7', 'cab234', self.gpdb_environment, secrets_environment=None, aws=self.aws)
    assert_that(release_fly.fly_ensure_logged_in(datetime=mock_datetime), equal_to(False))

  def test_fly_ensure_logged_in_calls_fly_sync_if_not_logged_in(self):
    mock_datetime = self.MockDatetime(self.after_expiry)
    self.gpdb_environment.command_runner.respond_to_command_with(
        ('fly', '-t', 'shared', 'login', '-n', 'GPDB', '-c', 'https://shared.ci.eng.pivotal.io'), exit_code=0)
    self.gpdb_environment.command_runner.respond_to_command_with(
        ('fly', '-t', 'shared', 'sync'), exit_code=1)
    release_fly = release.Release('4.3.27.7', 'cab234', self.gpdb_environment, secrets_environment=None, aws=self.aws)
    assert_that(release_fly.fly_ensure_logged_in(datetime=mock_datetime), equal_to(False))

  def test_fly_ensure_logged_in_extra_column_in_fly_targets(self):
    targets_output = (
        "name     url                                  junk      team      expiry\n"
        "sharded  https://shared.ci.eng.pivotal.io     ruh-roh   main      Thu, 26 Jan 2217 22:47:46 UTC\n"
        "shared   http://not-shared.ci.eng.pivotal.io  THX-1138  not-main  Thu, 26 Jan 2217 22:47:46 UTC\n"
        "shared   https://shared.ci.eng.pivotal.io     pdgb      gpdb      Thu, 26 Jan 2017 22:47:46 UTC\n"
    )
    self.gpdb_environment.command_runner.respond_to_command_with(
        ('fly', 'targets', '--print-table-headers'), output=targets_output)

    # Already logged in
    mock_datetime = self.MockDatetime(self.just_before_expiry)
    self.gpdb_environment.command_runner.respond_to_command_with(
        ('fly', '-t', 'shared', 'login', '-n', 'GPDB', '-c', 'https://shared.ci.eng.pivotal.io'), allowed=False)
    release_fly = release.Release('4.3.27.7', 'cab234', self.gpdb_environment, secrets_environment=None, aws=self.aws)
    assert_that(release_fly.fly_ensure_logged_in(datetime=mock_datetime))

  def test_fly_set_pipeline(self):
    self.gpdb_environment.command_runner.respond_to_command_with(
        ('fly', '-t', 'shared', 'set-pipeline', '--non-interactive',
         '-p', 'gpdb-4.3.29.7',
         '-c', self.gpdb_environment.path('ci/concourse/pipelines/pipeline.yml'),
         '-l', self.secrets_environment.path('gpdb-4.3.29.7-ci-secrets.yml')),
        exit_code=0)
    release_fly = release.Release('4.3.29.7', 'cab234', self.gpdb_environment, self.secrets_environment, aws=self.aws)
    assert_that(release_fly.fly_set_pipeline())

  def test_fly_set_pipeline_errors(self):
    self.gpdb_environment.command_runner.respond_to_command_with(
        ('fly', '-t', 'shared', 'set-pipeline', '--non-interactive',
         '-p', 'gpdb-4.3.28.7',
         '-c', self.gpdb_environment.path('ci/concourse/pipelines/pipeline.yml'),
         '-l', self.secrets_environment.path('gpdb-4.3.28.7-ci-secrets.yml')),
        exit_code=1)
    release_fly = release.Release('4.3.28.7', 'cab234', self.gpdb_environment, self.secrets_environment, aws=self.aws)
    assert_that(release_fly.fly_set_pipeline(), equal_to(False))


class CheckEnvironmentsTest(unittest.TestCase):
  class MockEnvironment(object):
    def __init__(self):
      self.check_dependencies = Spy(returns=True)
      self.check_git_can_pull = Spy(returns=True)
      self.check_git_status = Spy(returns=True)
      self.check_git_head_is_latest = Spy(returns=True)
      self.check_has_file = Spy(returns=True)

  class MockAws(object):
    def __init__(self):
      self.check_iam_user_within_account = Spy(returns=True)

  def setUp(self):
    self.gpdb_environment = self.MockEnvironment()
    self.secrets_environment = self.MockEnvironment()
    self.aws = self.MockAws()

  def test_checks_both_git_repositories(self):
    ret = release.check_environments(self.gpdb_environment, self.secrets_environment, printer=MockPrinter(), aws=self.aws)
    assert_that(ret)

    assert_that(self.gpdb_environment.check_dependencies.calls, greater_than(0))
    assert_that(self.gpdb_environment.check_git_can_pull.calls, greater_than(0))
    assert_that(self.gpdb_environment.check_git_status.calls, greater_than(0))
    assert_that(self.secrets_environment.check_git_can_pull.calls, greater_than(0))
    assert_that(self.secrets_environment.check_git_status.calls, greater_than(0))
    assert_that(self.secrets_environment.check_git_head_is_latest.calls, greater_than(0))
    assert_that(self.secrets_environment.check_has_file.calls, equal_to(1))
    assert_that(self.secrets_environment.check_has_file.last_args[0], equal_to('gpdb-4.3_STABLE-ci-secrets.yml'))
    assert_that(self.aws.check_iam_user_within_account.last_args[0], equal_to('189358390367'))

  def test_one_fails_but_still_runs_all(self):
    for i, failing_method in enumerate((
        self.gpdb_environment.check_dependencies,
        self.gpdb_environment.check_git_status,
        self.secrets_environment.check_git_status)):
      try:
        failing_method.returns = False

        ret = release.check_environments(self.gpdb_environment, self.secrets_environment, printer=MockPrinter(), aws=self.aws)
        assert_that(ret, equal_to(False))

        assert_that(self.gpdb_environment.check_dependencies.calls, equal_to(i+1))
        assert_that(self.gpdb_environment.check_git_status.calls, equal_to(i+1))
        assert_that(self.secrets_environment.check_git_status.calls, equal_to(i+1))
      finally:
        failing_method.returns = True

  def test_fails_from_multiple_failures(self):
    self.gpdb_environment.check_dependencies.returns = False
    self.secrets_environment.check_git_status.returns = False

    ret = release.check_environments(self.gpdb_environment, self.secrets_environment, printer=MockPrinter(), aws=self.aws)
    assert_that(ret, equal_to(False))

  def test_checks_for_template_secrets_file(self):
    ret = release.check_environments(self.gpdb_environment, self.secrets_environment, printer=MockPrinter(), aws=self.aws)
    assert_that(ret, equal_to(True))
    assert_that(self.secrets_environment.check_has_file.calls, equal_to(1))
    assert_that(self.secrets_environment.check_has_file.last_args[0], equal_to('gpdb-4.3_STABLE-ci-secrets.yml'))

  def test_checks_for_template_secrets_file_missing(self):
    self.secrets_environment.check_has_file.returns = False
    ret = release.check_environments(self.gpdb_environment, self.secrets_environment, printer=MockPrinter(), aws=self.aws)
    assert_that(ret, equal_to(False))
    assert_that(self.secrets_environment.check_has_file.calls, equal_to(1))
    assert_that(self.secrets_environment.check_has_file.last_args[0], equal_to('gpdb-4.3_STABLE-ci-secrets.yml'))


if __name__ == '__main__':
    unittest.main()
