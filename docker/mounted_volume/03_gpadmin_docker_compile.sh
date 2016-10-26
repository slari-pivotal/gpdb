#!/bin/bash
set -e
cd ~/gpdb4_mount/gpAux
source /opt/gcc_env.sh
make HOME=~/built-gpdb4 devel -j2
cp -r ~/gpdb4_mount/gpAux/gpdemo ~/gpdemo
source ~/built-gpdb4/greenplum-db-devel/greenplum_path.sh
cd ~/gpdemo
make cluster
