#!/bin/bash -l

## ----------------------------------------------------------------------
## General purpose functions
## ----------------------------------------------------------------------

function set_env() {
    export TERM=xterm-256color
    export TIMEFORMAT=$'\e[4;33mIt took %R seconds to complete this step\e[0m';
}

function number_of_cores() {
    local core_count
    core_count=$(grep -c 'core id' /proc/cpuinfo)
    echo "${core_count}"
}

## ----------------------------------------------------------------------
## Test functions
## ----------------------------------------------------------------------

function install_gpdb() {
    [ ! -d /usr/local/greenplum-db-devel ] && mkdir -p /usr/local/greenplum-db-devel
    tar -xzf bin_gpdb4/bin_gpdb4.tar.gz -C /usr/local/greenplum-db-devel
}

function install_sync_tools() {
    tar -xzf sync_tools_gpdb4/sync_tools_gpdb4.tar.gz -C gpdb4_src/gpAux
}

function configure() {
  pushd gpdb4_src/gpAux
      make INSTLOC=/usr/local/greenplum-db-devel ../GNUmakefile
  popd
}

function make_cluster() {
  source /usr/local/greenplum-db-devel/greenplum_path.sh
  pushd gpdb4_src/gpAux/gpdemo
      su gpadmin -c make cluster
  popd
}

function run_test() {
  ln -s "$(pwd)/gpdb4_src/gpAux/ext/rhel5_x86_64/python-2.6.2" /opt
  su - gpadmin -c "bash /opt/run_test.sh $(pwd)"
}
