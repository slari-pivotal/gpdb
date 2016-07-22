#!/bin/bash

set -e

if [[ ! -z "$TRACE" ]]; then
  set -x
fi

echo "source /usr/local/greenplum-db/greenplum_path.sh" >> ~gpadmin/.bashrc

for DATADIR in /data*; do
  mkdir -p $DATADIR/primary
  mkdir -p $DATADIR/mirror
done

chown gpadmin:gpadmin -R /data*/*
