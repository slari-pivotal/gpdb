#!/bin/bash -l

set -eox pipefail

CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${CWDIR}/common.bash"

function gen_env(){
  cat > /opt/run_test.sh <<-EOF
		source /usr/local/greenplum-db-devel/greenplum_path.sh
		source /opt/gcc_env.sh
		source \${1}/gpdb_src/gpAux/gpdemo/gpdemo-env.sh
		cd \${1}/gpdb_src/gpMgmt
		make -f Makefile.behave behave tags=${BEHAVE_TAGS}
	EOF

	chmod a+x /opt/run_test.sh
}

function setup_gpadmin_user() {
    ./gpdb_src/ci/concourse/scripts/setup_gpadmin_user.bash "$1"
}

function _main() {

    if [ -z "$BEHAVE_TAGS" ]; then
        echo "FATAL: BEHAVE_TAGS is not set"
        exit 1
    fi

    install_gpdb
    setup_gpadmin_user "$TEST_OS"
    make_cluster
    gen_env
    run_test
}

_main "$@"
