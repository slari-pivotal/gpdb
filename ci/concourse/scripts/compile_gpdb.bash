#!/bin/bash -l
set -exo pipefail

GREENPLUM_INSTALL_DIR=/usr/local/greenplum-db-devel
export GPPKGINSTLOC
GPPKGINSTLOC=$(pwd)/$OUTPUT_ARTIFACT_DIR

CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${CWDIR}/common.bash"

function prep_env_for_centos() {
  ln -sf "$(pwd)/gpdb_src/gpAux/ext/rhel5_x86_64/python-2.6.2" /opt
  export JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.39.x86_64
  export PATH=${JAVA_HOME}/bin:${PATH}
}

function prep_env_for_sles() {
  ln -sf "$(pwd)/gpdb_src/gpAux/ext/sles11_x86_64/python-2.6.2" /opt
  export JAVA_HOME=/usr/lib64/jvm/java-1.6.0-openjdk-1.6.0
  export PATH=${JAVA_HOME}/bin:${PATH}
}

function make_sync_tools() {
  pushd gpdb_src/gpAux
    make sync_tools
    tar -czf ../../sync_tools_gpdb/sync_tools_gpdb.tar.gz ext
  popd
}

function set_gcc() {
  if [ "$TARGET_OS" == "centos" ]; then
    # If centos 6 or above, use system defaults. Else source gcc environment to set gcc to 4.4.2
    if grep -q "release 5" /etc/redhat-release; then
      source /opt/gcc_env.sh
    fi
  else
    source /opt/gcc_env.sh
  fi
}

function build_gpdb() {
  pushd gpdb_src/gpAux
    make "$1" GPROOT=/usr/local dist
  popd
}

function build_gppkg() {
  pushd gpdb_src/gpAux
    make gppkg BLD_TARGETS="gppkg" INSTLOC="$GREENPLUM_INSTALL_DIR" GPPKGINSTLOC="$GPPKGINSTLOC" RELENGTOOLS=/opt/releng/tools
  popd
}

function unittest_check_gpdb() {
  pushd gpdb_src/gpAux
    make GPROOT=/usr/local unittest-check
  popd
}

function export_gpdb() {
  TARBALL="$GPPKGINSTLOC"/bin_gpdb.tar.gz
  pushd $GREENPLUM_INSTALL_DIR
    source greenplum_path.sh
    python -m compileall -x test .
    chmod -R 755 .
    tar -czf "${TARBALL}" ./*
  popd
}

function export_gpdb_extensions() {
  pushd gpdb_src/gpAux
    chmod 755 greenplum-*zip
    cp greenplum-*zip "$GPPKGINSTLOC"/
    chmod 755 "$GPPKGINSTLOC"/*.gppkg
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
    *)
      echo "only centos and sles are supported TARGET_OS'es"
      false
      ;;
  esac

  make_sync_tools
  # By default, only GPDB Server binary is build.
  # Use BLD_TARGETS flag with appropriate value string to generate client, loaders
  # connectors binaries
  if [ -n "$BLD_TARGETS" ]; then
    BLD_TARGET_OPTION=("BLD_TARGETS=\"$BLD_TARGETS\"")
  else
    BLD_TARGET_OPTION=("")
  fi
  set_gcc
  build_gpdb "${BLD_TARGET_OPTION[@]}"
  build_gppkg
  unittest_check_gpdb
  export_gpdb
  export_gpdb_extensions
}

_main "$@"
