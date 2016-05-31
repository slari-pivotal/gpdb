#!/bin/bash -l

set -euxo pipefail

function echo_expected_env_variables() {
  echo "$INSTALL_SCRIPT_SRC"
  echo "$GPDB_TARGZ"
  echo "$INSTALLER_ZIP"
}

function _main() {
  echo_expected_env_variables
  cat "$INSTALL_SCRIPT_SRC" "$GPDB_TARGZ" > installer_bin.bin
  chmod a+x installer_bin.bin
  zip "$INSTALLER_ZIP" installer_bin.bin
}

_main "$@"
