#!/bin/bash

set -e

if [[ ! -z "$TRACE" ]]; then
  set -x
fi

echo Unzipping ${ARCHIVE}
unzip -o ${ARCHIVE}

echo Running installer
echo -e "yes\n\nyes\nyes\n" | MORE=-1000 ./${INSTALLER}

echo "source /usr/local/greenplum-loaders*/greenplum_loaders_path.sh" >> ~gpadmin/.bashrc
