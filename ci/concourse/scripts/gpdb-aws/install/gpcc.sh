#!/bin/bash

set -e
if [[ ! -z "$TRACE" ]]; then
  set -x
fi

echo "Installing gpperfmon"

source /usr/local/greenplum-db/greenplum_path.sh

echo Unzipping ${ARCHIVE}
unzip -o ${ARCHIVE}

echo Running GPCC installer

echo -e "yes\n\nyes\nyes\n" | ./${INSTALLER}
export GPPERFMONHOME=/usr/local/greenplum-cc-web
source $GPPERFMONHOME/gpcc_path.sh

echo "export GPPERFMONHOME=/usr/local/greenplum-cc-web" >> ~gpadmin/.bashrc
echo "source \$GPPERFMONHOME/gpcc_path.sh" >> ~gpadmin/.bashrc

echo "$SEGMENT_HOSTS" > ~/hostfile
if [[ -n "$STANDBY" ]] && [[ "$STANDBY" -ge 1 ]]; then
  echo "smdw" >> ~/hostfile
fi
gpccinstall -f ~/hostfile

echo "Updating pg_hba"

if [[ $(hostname) == "mdw" ]]; then
  su - gpadmin -c "gpperfmon_install --enable --password gpmon --port 5432"

  if [[ -n "$STANDBY" ]] && [[ "$STANDBY" -ge 1 ]]; then
    echo "Copying over .pgpass file to smdw"
    su - gpadmin -c "scp ~/.pgpass smdw:~gpadmin/.pgpass"

    echo "Updating pg_hba on smdw"
    ssh smdw "echo \"local   gpperfmon         gpmon         md5\" >> ${MASTER_DATA_DIRECTORY}/pg_hba.conf"
    ssh smdw "echo \"host    gpperfmon      gpmon        127.0.0.1/28       md5\" >> ${MASTER_DATA_DIRECTORY}/pg_hba.conf"
  fi

  echo "Restarting gpdb"
  su - gpadmin -c "gpstop -a -r"
fi
