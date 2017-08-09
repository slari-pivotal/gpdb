#!/bin/bash
set -e
cd ~/gpdb4_mount/gpAux
source /opt/gcc_env.sh
make HOME=/usr/local devel -j2
cp -r ~/gpdb4_mount/gpAux/gpdemo ~/gpdemo
source /usr/local/greenplum-db-devel/greenplum_path.sh
cd ~/gpdemo
make cluster
