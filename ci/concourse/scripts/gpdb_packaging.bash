#!/bin/bash -l

set -euxo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function echo_expected_env_variables() {
  set +e
  vars=(
    # passed-in vars
    INSTALL_SCRIPT_SRC
    GPDB_TARGZ
    OS
    # derived vars
    GP_VERSION
    INSTALLER_ZIP
  )
  for v in "${vars[@]}" ; do
    echo "$v=${!v}"
  done
  set -e
}

function _main() {
  GP_VERSION=$("$DIR/../../../getversion" --short)
  INSTALLER_ZIP=packaged_gpdb/greenplum-db-${GP_VERSION}-${OS}.zip
  local installer_bin
  installer_bin=$(basename "$INSTALLER_ZIP" .zip).bin

  echo_expected_env_variables

  sed -i \
      -e "s:\(installPath=/usr/local/GP-\).*:\1$GP_VERSION:" \
      -e "s:\(installPath=/usr/local/greenplum-db-\).*:\1$GP_VERSION:" \
      "$INSTALL_SCRIPT_SRC"

  cat "$INSTALL_SCRIPT_SRC" "$GPDB_TARGZ" > "$installer_bin"
  chmod a+x "$installer_bin"
  zip "$INSTALLER_ZIP" "$installer_bin"
  openssl dgst -md5 "$INSTALLER_ZIP" > "$INSTALLER_ZIP".md5
}

_main "$@"
