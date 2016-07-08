#!/bin/bash

set -e

if [[ ! -z "$TRACE" ]]; then
  set -x
fi

echo "Creating hostfile"
echo "$SEGMENT_HOSTS" > ~/hostfile

echo "Running GPDB installer"
cd ~ && chmod a+x ./${INSTALLER}
mkdir -p /usr/local/greenplum-db
tail -n +$(awk '/^__END_HEADER__/ {print NR + 1; exit 0; }' ${INSTALLER}) ${INSTALLER} | tar xzf - -C /usr/local/greenplum-db
sed "s,^GPHOME.*,GPHOME=/usr/local/greenplum-db," -i /usr/local/greenplum-db/greenplum_path.sh

echo "source /usr/local/greenplum-db/greenplum_path.sh" >> ~gpadmin/.bashrc

mkdir -p /data1/master
chown gpadmin:gpadmin -R /data*/*

