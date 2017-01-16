from hamcrest import *
import os.path
import shutil
import tempfile
import unittest

import release
from release import Environment

# GETVERSION_TEMPLATE = """\
# #!/bin/bash
# GP_VERSION=%(version)s

# %(tail)s
# """


class EnvironmentTest(unittest.TestCase):
  class MockCommandRunner(object):
    def __init__(self, cwd='/proper/git/directory'):
      self.cwd = cwd
      self.subprocess_mock_outputs = {}
      self.respond_to_command_with(
          ('git', '--version'), output='git version 2.10.2')
      self.respond_to_command_with(
          ('git', 'status', '--porcelain'), output='')
      self.respond_to_command_with(
          ('git', 'rev-parse', '--show-toplevel'), output='/proper/git/directory')
      self.respond_to_command_with(
          ('git', 'ls-remote', 'origin', 'master'), output='abc123def456a78912323434\trefs/heads/master')
      self.respond_to_command_with(
          ('git', 'rev-parse', 'HEAD'), output='abc123def456a78912323434')
      self.respond_to_command_with(
          ('git', 'ls-remote', 'origin', '2>/dev/null'), exit_code=0)

    def respond_to_command_with(self, cmd, output=None, exit_code=0):
      self.subprocess_mock_outputs[cmd] = (output, exit_code)

    def get_subprocess_output(self, cmd):
      return self.subprocess_mock_outputs[cmd][0]

    def subprocess_is_successful(self, cmd):
      return 0 == self.subprocess_mock_outputs[cmd][1]

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

  def test_check_git_can_pull(self):
    environment = Environment(command_runner=self.MockCommandRunner())
    result = environment.check_git_can_pull()
    assert_that(result)

  def test_check_git_can_pull_fails(self):
    command_runner = self.MockCommandRunner()
    command_runner.respond_to_command_with(
        ('git', 'ls-remote', 'origin', '2>/dev/null'), exit_code=128)

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


class ReleaseTest(unittest.TestCase):
  class MockCommandRunner(object):
    def __init__(self, cwd='/proper/git/directory'):
      self.cwd = cwd
      self.subprocess_mock_outputs = {}
      self.respond_to_command_with(
          ('git', 'rev-parse', 'HEAD'), exit_code=0)

    def respond_to_command_with(self, cmd, output=None, exit_code=0):
      self.subprocess_mock_outputs[cmd] = (output, exit_code)

    def get_subprocess_output(self, cmd):
      return self.subprocess_mock_outputs[cmd][0]

    def subprocess_is_successful(self, cmd):
      return 0 == self.subprocess_mock_outputs[cmd][1]

  def test_check_rev(self):
    good_release = release.Release('1.2.3', 'HEAD')

    assert_that(good_release.check_rev())

  def test_check_rev(self):
    good_release = release.Release('1.2.3', 'HEAD')

    assert_that(good_release.check_rev())


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

class MockDirectory(object):
  def __init__(self, path, exists=True):
    self.exists = exists
    self.path = path

  def is_dir(self):
    return self.exists

class SecretsDirIsPresentTest(unittest.TestCase):
  def test_secrets_dir_is_present(self):
    good_dir = MockDirectory('/good/path')
    assert_that(release.secrets_dir_is_present(good_dir))

  def test_secrets_dir_is_not_present(self):
    bad_dir = MockDirectory('/bad/path', exists=False)
    result = release.secrets_dir_is_present(bad_dir)
    assert_that(result, equal_to(False))


class CheckEnvironmentsTest(unittest.TestCase):
  class MockEnvironment(object):
    def __init__(self):
      self.check_dependencies = Spy(returns=True)
      self.check_git_can_pull = Spy(returns=True)
      self.check_git_status = Spy(returns=True)
      self.check_git_head_is_latest = Spy(returns=True)
      self.check_has_file = Spy(returns=True)

  def setUp(self):
    self.gpdb_environment = self.MockEnvironment()
    self.secrets_environment = self.MockEnvironment()

  def test_checks_both_git_repositories(self):
    ret = release.check_environments(self.gpdb_environment, self.secrets_environment, printer=MockPrinter())
    assert_that(ret)

    assert_that(self.gpdb_environment.check_dependencies.calls, greater_than(0))
    assert_that(self.gpdb_environment.check_git_can_pull.calls, greater_than(0))
    assert_that(self.gpdb_environment.check_git_status.calls, greater_than(0))
    assert_that(self.secrets_environment.check_git_can_pull.calls, greater_than(0))
    assert_that(self.secrets_environment.check_git_status.calls, greater_than(0))
    assert_that(self.secrets_environment.check_git_head_is_latest.calls, greater_than(0))
    assert_that(self.secrets_environment.check_has_file.calls, equal_to(1))
    assert_that(self.secrets_environment.check_has_file.last_args[0], equal_to('gpdb-4.3_STABLE-ci-secrets.yml'))

  def test_one_fails_but_still_runs_all(self):
    for i, failing_method in enumerate((
        self.gpdb_environment.check_dependencies,
        self.gpdb_environment.check_git_status,
        self.secrets_environment.check_git_status)):
      try:
        failing_method.returns = False

        ret = release.check_environments(self.gpdb_environment, self.secrets_environment, printer=MockPrinter())
        assert_that(ret, equal_to(False))

        assert_that(self.gpdb_environment.check_dependencies.calls, equal_to(i+1))
        assert_that(self.gpdb_environment.check_git_status.calls, equal_to(i+1))
        assert_that(self.secrets_environment.check_git_status.calls, equal_to(i+1))
      finally:
        failing_method.returns = True

  def test_fails_from_multiple_failures(self):
    self.gpdb_environment.check_dependencies.returns = False
    self.secrets_environment.check_git_status.returns = False

    ret = release.check_environments(self.gpdb_environment, self.secrets_environment, printer=MockPrinter())
    assert_that(ret, equal_to(False))

  def test_checks_for_template_secrets_file(self):
    ret = release.check_environments(self.gpdb_environment, self.secrets_environment, printer=MockPrinter())
    assert_that(ret, equal_to(True))
    assert_that(self.secrets_environment.check_has_file.calls, equal_to(1))
    assert_that(self.secrets_environment.check_has_file.last_args[0], equal_to('gpdb-4.3_STABLE-ci-secrets.yml'))

  def test_checks_for_template_secrets_file_missing(self):
    self.secrets_environment.check_has_file.returns = False
    ret = release.check_environments(self.gpdb_environment, self.secrets_environment, printer=MockPrinter())
    assert_that(ret, equal_to(False))
    assert_that(self.secrets_environment.check_has_file.calls, equal_to(1))
    assert_that(self.secrets_environment.check_has_file.last_args[0], equal_to('gpdb-4.3_STABLE-ci-secrets.yml'))


if __name__ == '__main__':
    unittest.main()
