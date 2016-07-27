#!/bin/bash -l

set -euxo pipefail

function unit_test(){
	cat > /home/gpadmin/run_test.sh <<-EOF
	# Use own toolchain for unit tests
	source /opt/rh/devtoolset-2/enable

	cd "\${1}/gpdb_src/gpAux/extensions/gps3ext"
	set -euxo pipefail
	make test
	EOF

	chown -R gpadmin:gpadmin $(pwd)
	chown gpadmin:gpadmin /home/gpadmin/run_test.sh
	chmod a+x /home/gpadmin/run_test.sh
}

function _main() {
	unit_test

	su - gpadmin -c "bash -e /home/gpadmin/run_test.sh $(pwd)"
}

_main "$@"
