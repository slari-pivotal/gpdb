#!/bin/bash -l

set -exo pipefail

CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${CWDIR}/common.bash"

function gen_env(){
	cat > /home/gpadmin/run_regression_gpcheckcloud.sh <<-EOF
	set -exo pipefail

	source /opt/gcc_env.sh
	source /usr/local/greenplum-db-devel/greenplum_path.sh

	cd "\${1}/gpdb_src/gpAux/extensions/gps3ext"
	make -B gpcheckcloud

	cd "\${1}/gpdb_src/gpAux/extensions/gps3ext/regress"
	bash gpcheckcloud_regress.sh
	EOF

	chown -R gpadmin:gpadmin $(pwd)
	chown gpadmin:gpadmin /home/gpadmin/run_regression_gpcheckcloud.sh
	chmod a+x /home/gpadmin/run_regression_gpcheckcloud.sh
}

function run_regression_gpcheckcloud() {
	su - gpadmin -c "bash /home/gpadmin/run_regression_gpcheckcloud.sh $(pwd)"
}

function setup_gpadmin_user() {
	./gpdb_src/ci/concourse/scripts/setup_gpadmin_user.bash "centos"
}

function _main() {
	time install_sync_tools
	ln -s "$(pwd)/gpdb_src/gpAux/ext/rhel5_x86_64/python-2.6.2" /opt

	time configure
	time install_gpdb
	time setup_gpadmin_user
	time gen_env

	echo -n "$s3conf" | base64 -d > /home/gpadmin/s3.conf
	chown gpadmin:gpadmin /home/gpadmin/s3.conf

	time run_regression_gpcheckcloud
}

_main "$@"
