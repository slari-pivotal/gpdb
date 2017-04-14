#!/bin/bash -l

set -euxo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

substitute_GP_VERSION() {
  GP_VERSION=$("$DIR/../../../getversion" --short)
  INSTALLER_ZIP=${INSTALLER_ZIP//@GP_VERSION@/${GP_VERSION}}
}

function echo_expected_env_variables() {
  set +e
  vars=(
    INSTALL_SCRIPT_SRC
    GPDB_TARGZ
    INSTALLER_ZIP
  )
  for v in "${vars[@]}" ; do
    echo "$v=${!v}"
  done
  set -e
}

function _main() {
  substitute_GP_VERSION
  echo_expected_env_variables

  local installer_bin
  installer_bin=$(basename "$INSTALLER_ZIP" .zip).bin

  sed -i \
      -e "s:\(installPath=/usr/local/GP-\).*:\1$GP_VERSION:" \
      -e "s:\(installPath=/usr/local/greenplum-db-\).*:\1$GP_VERSION:" \
      "$INSTALL_SCRIPT_SRC"

  cat "$INSTALL_SCRIPT_SRC" "$GPDB_TARGZ" > "$installer_bin"
  chmod a+x "$installer_bin"
  zip "$INSTALLER_ZIP" "$installer_bin"
  openssl dgst -sha256 "$INSTALLER_ZIP" > "$INSTALLER_ZIP".sha256
}

_main "$@"
