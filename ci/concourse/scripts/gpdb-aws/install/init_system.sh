#!/bin/bash

set -e

if [[ ! -z "$TRACE" ]]; then
  set -x
fi

echo "Preparing ~gpadmin/gpconfigs"

mkdir -p ~gpadmin/gpconfigs
cp /usr/local/greenplum-db/docs/cli_help/gpconfigs/gpinitsystem_config ~gpadmin/gpconfigs/
echo "$SEGMENT_HOSTS" > ~gpadmin/gpconfigs/hostfile_gpinitsystem

chown gpadmin:gpadmin -R ~gpadmin/gpconfigs

sed -i -r "s/#MACHINE_LIST_FILE/MACHINE_LIST_FILE/" ~gpadmin/gpconfigs/gpinitsystem_config

sed -i -r "s/#MIRROR_PORT_BASE/MIRROR_PORT_BASE/" ~gpadmin/gpconfigs/gpinitsystem_config
sed -i -r "s/#REPLICATION_PORT_BASE/REPLICATION_PORT_BASE/" ~gpadmin/gpconfigs/gpinitsystem_config
sed -i -r "s/#MIRROR_REPLICATION_PORT_BASE/MIRROR_REPLICATION_PORT_BASE/" ~gpadmin/gpconfigs/gpinitsystem_config
sed -i -r "s/#declare -a MIRROR_DATA_DIRECTORY/declare -a MIRROR_DATA_DIRECTORY/" ~gpadmin/gpconfigs/gpinitsystem_config

sed -i -r "s| DATA_DIRECTORY=\(.*\)| DATA_DIRECTORY\=\(${DATA_DIRECTORY}\)|" ~gpadmin/gpconfigs/gpinitsystem_config
sed -i -r "s| MIRROR_DATA_DIRECTORY=\(.*\)| MIRROR_DATA_DIRECTORY\=\(${MIRROR_DATA_DIRECTORY}\)|" ~gpadmin/gpconfigs/gpinitsystem_config

sed -i -r "s|MASTER_DIRECTORY=/data/master|MASTER_DIRECTORY=${MASTER_DIRECTORY}|" ~gpadmin/gpconfigs/gpinitsystem_config
echo "Running gpinitsystem"

source /usr/local/greenplum-db/greenplum_path.sh

cp ~root/hostfile ~gpadmin/hostfile
chown gpadmin:gpadmin ~gpadmin/hostfile

gpseginstall -f ~gpadmin/hostfile -p changeme

if [[ "$STANDBY" -ge 1 ]]; then
  echo | su - gpadmin -c "bash -c 'gpinitsystem -a -c ~gpadmin/gpconfigs/gpinitsystem_config -s smdw'" || [[ $? -lt 2 ]]
else
  echo | su - gpadmin -c "bash -c 'gpinitsystem -a -c ~gpadmin/gpconfigs/gpinitsystem_config'" || [[ $? -lt 2 ]]
fi

