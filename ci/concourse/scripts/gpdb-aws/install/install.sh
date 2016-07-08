#!/bin/bash

set -e
set -o pipefail

if [[ ! -z "$TRACE" ]]; then
  set -x
fi

usage() {
  echo >&2 "Install GPDB onto EC2 cluster"
  echo >&2 ""
  echo >&2 "Usage:"
  echo >&2 "./install.sh </path/to/external/hostfile> [</path/to/internal/hostfile>]"
  echo >&2 ""
  echo >&2 "Environment Variables:"
  echo >&2 ""
  echo >&2 "GREENPLUM_DB        - Path to Greenplum Data Computing Appliance Database Installer bin file"
  echo >&2 "GREENPLUM_LOADERS   - Path to Greenplum Database Loaders (RHEL x86_64) zip file"
  echo >&2 "GREENPLUM_CC        - Path to Greenplum Command Center (RHEL x86_64) zip file"
  echo >&2 ""
  echo >&2 "AWS_KEYPAIR         - Path to AWS Key"
  echo >&2 ""
  echo >&2 "SEGMENTS            - Number of segments per segment host (Default: 8)"
  echo >&2 ""
}

BASEDIR=$(cd "${0%/*}"; pwd)

if [[ -z $WORK_DIR ]]; then
  WORK_DIR=${BASEDIR}/.log/$(date +%F)/$(date "+%H%M")
fi

LOGFILE="${WORK_DIR}/$(basename ${BASH_SOURCE[0]} .sh).log"

mkdir -p ${WORK_DIR}

log() {
  echo -e "$@"
  echo -e "$@" >> ${LOGFILE}
}

extended_log() {
  echo -e "$@" >> ${LOGFILE}
}

error() {
  echo >&2 "$@"
  echo -e "$@" >> ${LOGFILE}

  exit 1
}

EXTERNAL_HOSTS=$1
INTERNAL_HOSTS=$2

if [[ -z "$EXTERNAL_HOSTS" ]]; then
  error Hostfile must be specified

  usage
fi

if [[ -z "$INTERNAL_HOSTS" ]]; then
  log "Internal hostfile not specified, using ${EXTERNAL_HOSTS}"
  INTERNAL_HOSTS=${EXTERNAL_HOSTS}
fi

if [[ -z $GREENPLUM_DB ]]; then
  error "\$GREENPLUM_DB must be specified"

  usage
fi

if [[ -z $GREENPLUM_LOADERS ]]; then
  log "\$GREENPLUM_LOADERS not specified, will not setup ETLs"
fi

if [[ -z $GREENPLUM_CC ]]; then
  log "\$GREENPLUM_CC not specified, will not setup Command Center"
fi

if [[ -z $AWS_KEYPAIR ]]; then
  error "\$AWS_KEYPAIR must be specified"

  usage
fi

if [[ -z $SEGMENTS ]]; then
  SEGMENTS=8
fi

if [[ -z "$MASTER_DIRECTORY" ]]; then
  MASTER_DIRECTORY=/data1/master
fi

if [[ -z "$DATA_DIRECTORY" ]]; then
  DATA_DIRECTORY="/data1/primary /data1/primary /data1/primary /data1/primary /data1/primary /data1/primary /data1/primary /data1/primary"
fi

if [[ -z "$MIRROR_DATA_DIRECTORY" ]]; then
  MIRROR_DATA_DIRECTORY="/data1/mirror /data1/mirror /data1/mirror /data1/mirror /data1/mirror /data1/mirror /data1/mirror /data1/mirror"
fi

MASTER_IP=$(grep " mdw" $EXTERNAL_HOSTS | xargs -n 2 | cut -f1 -d' ')

STANDBY_MASTER_IP=$(grep " smdw" $EXTERNAL_HOSTS | xargs -n 2 | cut -f1 -d' ') || true

SEGMENT_IPS=$(grep " sdw" $EXTERNAL_HOSTS | xargs -n 2 | cut -f1 -d' ') || true
ETL_IPS=$(grep " etl" $EXTERNAL_HOSTS | xargs -n 2 | cut -f1 -d' ') || true

SEGMENT_HOSTS=$(grep " sdw" $EXTERNAL_HOSTS | xargs -n 2 | cut -f2 -d' ') || true
ETL_HOSTS=$(grep " etl" $EXTERNAL_HOSTS | xargs -n 2 | cut -f2 -d' ') || true

if [[ -z "$SEGMENT_IPS" || -z "$SEGMENT_HOSTS" ]]; then
  if [[ -z "$STANDBY_MASTER_IP" ]]; then
    log "No segments found, assuming single node installation"
    SEGMENT_IPS=($MASTER_IP)
    SEGMENT_HOSTS=(mdw)
  else
    log "Standby master but no segments found, assuming dual node installation"
    SEGMENT_IPS=("$MASTER_IP" "$STANDBY_MASTER_IP")
    SEGMENT_HOSTS=$(echo -e "mdw\nsmdw")
  fi
fi

trap '[[ $? != 0 ]] && log Failed. Run with TRACE=1 to see full output' EXIT

main() {
  log "Installing Greenplum Database"

  log "Setting up ${MASTER_IP} as master"
  setup_master $MASTER_IP

  if [[ ! -z "$STANDBY_MASTER_IP" ]]; then
    log "Setting up ${STANDBY_MASTER_IP} as master"
    setup_master $STANDBY_MASTER_IP
  fi

  for IP in ${SEGMENT_IPS[*]}; do
    log "Setting ip ${IP} as segment"
    setup_segment $IP
  done

  if [[ ! -z "$GREENPLUM_LOADERS" ]]; then
    for IP in ${ETL_IPS[*]}; do
      setup_etl $IP
    done
  fi

  initialize_system $MASTER_IP
  postinitialize_system $MASTER_IP

  if [[ -n $STANDBY_MASTER_IP ]]; then
    postinitialize_system $STANDBY_MASTER_IP
  fi

  if [[ ! -z "$GREENPLUM_CC" ]]; then
    install_gpcc $MASTER_IP

    if [[ -n $STANDBY_MASTER_IP ]]; then
      install_gpcc $STANDBY_MASTER_IP
    fi

    initialize_gpcc $MASTER_IP
  fi

  echo "Logs written to ${LOGFILE}"
}

setup_master() {
  local IP=$1
  log "Setup master ${IP}"

  local INSTALLER=$(basename $GREENPLUM_DB)

  local EXPORTS="
export SEGMENT_HOSTS=\"$SEGMENT_HOSTS\"
export ETL_HOSTS=\"$SEGMENT_HOSTS\"
export INSTALLER=\"$INSTALLER\"
export TRACE=\"$TRACE\"
"
  rsync -e "ssh -i ${AWS_KEYPAIR}" -az --no-o --no-g "$GREENPLUM_DB" root@$IP:~

  echo -e "$EXPORTS" | cat - ${BASEDIR}/master.sh | ssh -i ${AWS_KEYPAIR} root@$IP 'bash -s'
}

setup_etl() {
  local IP=$1
  log "Setup etl ${IP}"

  local ARCHIVE=$(basename $GREENPLUM_LOADERS)
  local INSTALLER=$(basename ${GREENPLUM_LOADERS%.*}.bin)

  local EXPORTS="
export ARCHIVE=\"$ARCHIVE\"
export INSTALLER=\"$INSTALLER\"
export TRACE=\"$TRACE\"
"
  rsync -e "ssh -i ${AWS_KEYPAIR}" -az --no-o --no-g "$GREENPLUM_LOADERS" root@$IP:~

  echo -e "$EXPORTS" | cat - ${BASEDIR}/etl.sh | ssh -i ${AWS_KEYPAIR} root@$IP 'bash -s'
}

setup_segment() {
  local IP=$1
  log "Setup sdw ${IP}"

  local EXPORTS="
export TRACE=\"$TRACE\"
"
  echo -e "$EXPORTS" | cat - ${BASEDIR}/segment.sh | ssh -i ${AWS_KEYPAIR} root@$IP 'bash -s'

  DATA_DIRECTORY=$(ssh -i ${AWS_KEYPAIR} root@$IP "yes \"\`find /data* -name \"primary\"\`\" | head -n ${SEGMENTS} | xargs")
  MIRROR_DATA_DIRECTORY=$(ssh -i ${AWS_KEYPAIR} root@$IP "yes \"\`find /data* -name \"mirror\"\`\" | head -n ${SEGMENTS} | xargs")
}

initialize_system() {
  local IP=$1

  local INTERNAL_ETL_IPS=$(cat $INTERNAL_HOSTS | grep etl | xargs -n 2 | cut -f1 -d " ")
  local EXPORTS="
export MASTER_DIRECTORY=\"$MASTER_DIRECTORY\"
export DATA_DIRECTORY=\"$DATA_DIRECTORY\"
export MIRROR_DATA_DIRECTORY=\"$MIRROR_DATA_DIRECTORY\"
export SEGMENTS=\"$SEGMENTS\"
export SEGMENT_HOSTS=\"$SEGMENT_HOSTS\"
export INTERNAL_ETL_IPS=\"$INTERNAL_ETL_IPS\"
export TRACE=\"$TRACE\"
export STANDBY=\"$STANDBY\"
"

  echo -e "$EXPORTS" | cat - ${BASEDIR}/init_system.sh | ssh -i ${AWS_KEYPAIR} root@$IP 'bash -s'
}

postinitialize_system() {
  local IP=$1

  local INTERNAL_ETL_IPS=$(cat $INTERNAL_HOSTS | grep etl | xargs -n 2 | cut -f1 -d " ")
  local EXPORTS="
export MASTER_DIRECTORY=\"$MASTER_DIRECTORY\"
export DATA_DIRECTORY=\"$DATA_DIRECTORY\"
export MIRROR_DATA_DIRECTORY=\"$MIRROR_DATA_DIRECTORY\"
export SEGMENTS=\"$SEGMENTS\"
export SEGMENT_HOSTS=\"$SEGMENT_HOSTS\"
export INTERNAL_ETL_IPS=\"$INTERNAL_ETL_IPS\"
export TRACE=\"$TRACE\"
export STANDBY=\"$STANDBY\"
"

  echo -e "$EXPORTS" | cat - ${BASEDIR}/postinit_system.sh | ssh -i ${AWS_KEYPAIR} ${SSH_USER}@$IP 'bash -s'
}

install_gpcc() {
  local IP=$1
  log "Setup gpcc ${IP}"

  local SEGMENT_HOSTS=$(cat $INTERNAL_HOSTS | grep sdw | xargs -n 2 | cut -f2 -d " ")
  local ARCHIVE=$(basename $GREENPLUM_CC)
  local INSTALLER=$(basename ${GREENPLUM_CC%.*}.bin)
  local EXPORTS="
export ARCHIVE=\"$ARCHIVE\"
export INSTALLER=\"$INSTALLER\"
export TRACE=\"$TRACE\"
export MASTER_DATA_DIRECTORY=\"/data1/master/gpseg-1\"
export SEGMENT_HOSTS=\"$SEGMENT_HOSTS\"
export ETL_HOSTS=\"$ETL_HOSTS\"
export STANDBY=\"$STANDBY\"
"
  rsync -e "ssh -i \"${AWS_KEYPAIR}\"" -az --no-o --no-g "$GREENPLUM_CC" root@$IP:~

  echo -e "$EXPORTS" | cat - ${BASEDIR}/gpcc.sh | ssh -i "${AWS_KEYPAIR}" root@$IP 'bash -s'
}

initialize_gpcc() {
  local IP=$1
  log "Setup gpcc ${IP}"

  local SEGMENT_HOSTS=$(cat $INTERNAL_HOSTS | grep sdw | xargs -n 2 | cut -f2 -d " ")
  local ARCHIVE=$(basename $GREENPLUM_CC)
  local INSTALLER=$(basename ${GREENPLUM_CC%.*}.bin)
  local EXPORTS="
export ARCHIVE=\"$ARCHIVE\"
export INSTALLER=\"$INSTALLER\"
export TRACE=\"$TRACE\"
export MASTER_DATA_DIRECTORY=\"/data1/master/gpseg-1\"
export SEGMENT_HOSTS=\"$SEGMENT_HOSTS\"
export ETL_HOSTS=\"$ETL_HOSTS\"
export STANDBY=\"$STANDBY\"
"
  echo -e "$EXPORTS" | cat - ${BASEDIR}/init_gpcc.sh | ssh -i "${AWS_KEYPAIR}" root@$IP 'bash -s'
}

main "$@"
