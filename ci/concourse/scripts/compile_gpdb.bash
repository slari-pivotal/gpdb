#!/bin/bash -l
set -exo pipefail

GREENPLUM_INSTALL_DIR=/usr/local/greenplum-db-devel
export GPDB_ARTIFACTS_DIR
GPDB_ARTIFACTS_DIR=$(pwd)/$OUTPUT_ARTIFACT_DIR

CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${CWDIR}/common.bash"

function prep_env_for_sles() {
  ln -sf "$(pwd)/gpdb_src/gpAux/ext/sles11_x86_64/python-2.6.2" /opt
  export JAVA_HOME=/usr/lib64/jvm/java-1.6.0-openjdk-1.6.0
  export PATH=${JAVA_HOME}/bin:${PATH}
  source /opt/gcc_env.sh
}

function build_gpdb() {
  pushd gpdb_src/gpAux
    if [ -n "$1" ]; then
      make "$1" GPROOT=/usr/local dist
    else
      make GPROOT=/usr/local dist
    fi
  popd
}

function build_gppkg() {
  pushd gpdb_src/gpAux
    make gppkg BLD_TARGETS="gppkg" INSTLOC="$GREENPLUM_INSTALL_DIR" GPPKGINSTLOC="$GPDB_ARTIFACTS_DIR" RELENGTOOLS=/opt/releng/tools
  popd
}

function unittest_check_gpdb() {
  pushd gpdb_src/gpAux
    source $GREENPLUM_INSTALL_DIR/greenplum_path.sh
    make GPROOT=/usr/local unittest-check
  popd
}

function export_gpdb() {
  TARBALL="$GPDB_ARTIFACTS_DIR"/bin_gpdb.tar.gz
  pushd $GREENPLUM_INSTALL_DIR
    source greenplum_path.sh
    python -m compileall -x test .
    chmod -R 755 .
    tar -czf "${TARBALL}" ./*
  popd
}

function export_gpdb_extensions() {
  pushd gpdb_src/gpAux
    if [ -f greenplum-*zip* ] ; then
      chmod 755 greenplum-*zip*
      cp greenplum-*zip* "$GPDB_ARTIFACTS_DIR"/
    fi
    if [ -f "$GPDB_ARTIFACTS_DIR"/*.gppkg ] ; then
      chmod 755 "$GPDB_ARTIFACTS_DIR"/*.gppkg
    fi
  popd
}

function _main() {
  case "$TARGET_OS" in
    centos)
      prep_env_for_centos
      ;;
    sles)
      prep_env_for_sles
      ;;
    win32)
      export BLD_ARCH=win32
      ;;
    *)
      echo "only centos and sles are supported TARGET_OS'es"
      false
      ;;
  esac

  generate_build_number
  make_sync_tools
  # By default, only GPDB Server binary is build.
  # Use BLD_TARGETS flag with appropriate value string to generate client, loaders
  # connectors binaries
  if [ -n "$BLD_TARGETS" ]; then
    BLD_TARGET_OPTION=("BLD_TARGETS=\"$BLD_TARGETS\"")
  else
    BLD_TARGET_OPTION=("")
  fi
  build_gpdb "${BLD_TARGET_OPTION[@]}"
  build_gppkg
  if [ "$TARGET_OS" != "win32" ] ; then
    # Don't unit test when cross compiling. Tests don't build because they
    # require `./configure --with-zlib`.
    unittest_check_gpdb
  fi
  export_gpdb
  export_gpdb_extensions
}

_main "$@"
