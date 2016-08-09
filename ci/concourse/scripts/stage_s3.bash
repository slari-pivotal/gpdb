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

	echo -n "$EC2_PRIVATE_KEY" >/home/gpadmin/key.b64
	base64 -d /home/gpadmin/key.b64 >/home/gpadmin/key
	
	chmod 600 /home/gpadmin/key
	cd gpdb_src/gpAux/extensions/gps3ext

	scp -i /home/gpadmin/key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null gps3ext.so gpadmin@$EC2_IP:/home/gpadmin/greenplum-db/lib/postgresql/

	ssh -i /home/gpadmin/key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null gpadmin@$EC2_IP "source /home/gpadmin/greenplum-db-data/env/env.sh; source /home/gpadmin/greenplum-db/greenplum_path.sh; gpstop -arf"
}

_main "$@"
