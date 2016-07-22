#!/bin/bash

set -e

if [[ ! -z "$TRACE" ]]; then
  set -x
fi

echo "Creating hostfile"
echo "$SEGMENT_HOSTS" > ~/hostfile

echo "Running GPDB installer"
cd ~ && chmod a+x ./${INSTALLER}
./${INSTALLER}

echo "source /usr/local/greenplum-db/greenplum_path.sh" >> ~gpadmin/.bashrc

mkdir -p /data1/master
chown gpadmin:gpadmin -R /data*/*

