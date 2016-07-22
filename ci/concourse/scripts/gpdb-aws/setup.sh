#!/bin/bash

set -e

if [[ ! -z "$TRACE" ]]; then
  set -x
fi

CLUSTER_ID=cluster-$(echo $RANDOM $(date "+%s") | cksum | cut -f1 -d' ' | cut -c1-8)
CLUSTER_DIR=~/.gpcloud/${CLUSTER_ID}

usage() {
  echo >&2 "Create GPDB cluster on AWS"
  echo >&2 ""
  echo >&2 "Usage: $0 <number of segment hosts>"
  echo >&2 ""
  echo >&2 "Environment Variables:"
  echo >&2 ""
  echo >&2 "AWS_ACCESS_KEY            - AWS Access Key"
  echo >&2 "AWS_SECRET_KEY            - AWS Secret Key"
  echo >&2 "AWS_KEYPAIR               - AWS Keypair Path"
  echo >&2 ""
  echo >&2 "GREENPLUM_DB              - Path to Greenplum Data Computing Appliance Database Installer bin file"
  echo >&2 "GREENPLUM_LOADERS         - Path to Greenplum Database Loaders (RHEL x86_64) zip file"
  echo >&2 "GREENPLUM_CC              - Path to Greenplum Command Center (RHEL x86_64) zip file"
  echo >&2 ""
}

log() {
  echo -e "$@"
}

error() {
  echo >&2 "$@"

  exit 1
}

SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]}")

SEGMENT_HOSTS=$1

if [[ -z "$SEGMENT_HOSTS" ]]; then
  usage

  error "Number of segment hosts must be specified"
fi

if [[ -z $AWS_ACCESS_KEY ]]; then
  usage

  error "\$AWS_ACCESS_KEY must be specified."
fi

if [[ -z $AWS_SECRET_KEY ]]; then
  usage

  error "\$AWS_SECRET_KEY must be specified."
fi

if [[ -z $AWS_KEYPAIR ]]; then
  usage

  error "\$AWS_KEYPAIR must be specified."
fi

if [[ -z $GREENPLUM_DB ]]; then
  usage

  error "\$GREENPLUM_DB must be specified"
fi


trap '[[ $? != 0 ]] && log Failed. See logs in ${CLUSTER_DIR}' EXIT

main() {
  log "Creating GPDB cluster on AWS"
  log "${INSTANCES} instances"

  create_cluster

  provision_instances

  prepare_instances

  install_software

  generate_report
}

create_cluster() {
  mkdir -p ${CLUSTER_DIR}

  export WORK_DIR=${CLUSTER_DIR}
}

provision_instances() {
  ${SCRIPTS_DIR}/provision/provision.sh ${SEGMENT_HOSTS}
}

prepare_instances() {
  ${SCRIPTS_DIR}/prepare/prepare.sh ${WORK_DIR}/external-hosts ${WORK_DIR}/internal-hosts
}

install_software() {
  ${SCRIPTS_DIR}/install/install.sh ${WORK_DIR}/external-hosts ${WORK_DIR}/internal-hosts
}

generate_report() {
  log "Cluster creation complete"

  MASTER=$(cat ${WORK_DIR}/external-hosts | grep mdw | grep -v smdw | xargs -n 2 | cut -f1 -d' ')

  log "Greenplum Database running on ${MASTER}"

  ETL=$(cat ${WORK_DIR}/external-hosts | grep etl | xargs -n 2 | cut -f1 -d' ')

  if [[ ! -z $ETL ]]; then
    log "ETL host: ${ETL[*]}"
  fi

  if [[ ! -z "$GREENPLUM_CC" ]]; then
    log "Greenplum Command Center running on http://${MASTER}:28080/ (login: gpmon/gpmon)"
  fi

  log "Hostfile: ${WORK_DIR}/external-hosts"

  log "Logs available in ${WORK_DIR}"
}

main "$@"
