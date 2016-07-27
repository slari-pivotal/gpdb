#!/bin/bash -l

set -exo pipefail

function gen_env(){
	cat > /home/gpadmin/run_make.sh <<-EOF
	source /opt/gcc_env.sh
	ln -s "$(pwd)/gpdb_src/gpAux/ext/rhel5_x86_64/python-2.6.2" /opt
	source /home/gpadmin/greenplum-db-devel/greenplum_path.sh

	cd "\${1}/gpdb_src/gpAux/extensions/gps3ext"
	make
	EOF

	chown -R gpadmin:gpadmin $(pwd)
	chown gpadmin:gpadmin /home/gpadmin/run_make.sh
	chmod a+x /home/gpadmin/run_make.sh
}

function _main() {
	gen_env

	su - gpadmin -c "bash /home/gpadmin/run_make.sh $(pwd)"
}

_main "$@"
