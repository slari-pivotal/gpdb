#!/bin/bash

set -e
set -o pipefail

if [[ ! -z "$TRACE" ]]; then
  set -x
fi

usage() {
  echo >&2 "Provision EC2 cluster for GPDB"
  echo >&2 ""
  echo >&2 "Usage:"
  echo >&2 "./provision.sh <# of segment hosts>"
  echo >&2 ""
  echo >&2 "Environment Variables:"
  echo >&2 ""
  echo >&2 "AWS_ACCESS_KEY            - AWS Access Key"
  echo >&2 "AWS_SECRET_KEY            - AWS Secret Key"
  echo >&2 "AWS_KEYPAIR               - AWS Keypair Path"
  echo >&2 ""
  echo >&2 "AMI                       - Centos 6 HVM AMI (Default: ami-c2a818aa)"
  echo >&2 "INSTANCE_TYPE             - EC2 Instance Type (Default: i2.8xlarge)"
  echo >&2 ""
  echo >&2 "VPC_ID                    - VPC for subnet (Default: not set)"
  echo >&2 "SUBNET_ID                 - Subnet for instances (Default: not set)"
  echo >&2 ""
  echo >&2 "ETL_RATIO                 - Number of segment hosts per ETL host (Default: 4)"
  echo >&2 "ETL_HOSTS                 - Number of ETL hosts (Default: # of segment hosts / \$ETL_RATIO)"
  echo >&2 ""
  echo >&2 "STANDBY                   - Number of standby master nodes, can be 0 or 1 (Default: 0)"
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

KEYNAME=$(basename "${AWS_KEYPAIR%.*}")

if [[ -z $AMI ]]; then
  AMI="ami-c2a818aa"
fi

if [[ -z "$SSH_USER" ]]; then
  SSH_USER=root
fi

if [[ -z $IMAGE_VERSION ]]; then
  IMAGE_VERSION=$(date -v-mon +"%Y-%m-%d" 2> /dev/null || date -d-mon +"%Y-%m-%d")
fi

if [[ -z $IMAGE_NAME ]]; then
  IMAGE_NAME="Greenplum Database Virtual Appliance"
fi

if [[ -z $INSTANCE_TYPE ]]; then
  INSTANCE_TYPE="i2.8xlarge"
fi

SEGMENT_HOSTS=$1
if [[ -z $SEGMENT_HOSTS ]]; then
  usage

  error "Number of SEGMENT_HOSTS must be specified."
fi

if [[ -z $ETL_RATIO ]]; then
  ETL_RATIO=4
fi

if [[ -n "$STANDBY" ]] && [[ "$STANDBY" != "0" ]]; then
  STANDBY=1
else
  STANDBY=0
fi

if [[ -z $ETL_HOSTS ]]; then
  ETL_HOSTS=$(( ($SEGMENT_HOSTS + $ETL_RATIO - 1) / $ETL_RATIO ))
fi

if [[ -z "$DEDICATED" ]]; then
  TENANCY=default
else
  TENANCY=dedicated
fi

INSTANCES=$((1 + $STANDBY + $SEGMENT_HOSTS + $ETL_HOSTS))

if [[ -z $RETRIES ]]; then
  RETRIES=120
fi

if [[ -z $WAIT ]]; then
  WAIT=15
fi

trap '[[ $? != 0 ]] && log Failed. Run with TRACE=1 to see full output' EXIT

main() {
  log "Provisioning ${INSTANCES} '${INSTANCE_TYPE}' instances"
  log "  1 master host, ${STANDBY} standby master host(s)"
  log "  ${SEGMENT_HOSTS} segment host(s)"
  log "  ${ETL_HOSTS} etl host(s)"

  log "Using keypair: ${KEYNAME}"

  check_tools

  create_vpc
  create_subnet

  create_image

  run_instances

  create_hostfiles
  rename_instances

  print_addresses

  log "Logs written to ${LOGFILE}"
}

check_tools() {
  if ! command -v ec2-run-instances >/dev/null 2>&1; then
    error "Amazon EC2 API Tools not installed (see http://aws.amazon.com/developertools/351)"
  fi
}

create_image() {
  log "Creating Image"

  local NAME="${IMAGE_NAME} (Version ${IMAGE_VERSION} - Key ${KEYNAME} - Base ${AMI})"

  if IMAGE_ID=$(ec2-describe-images --show-empty-fields | grep IMAGE | grep "${NAME}" | cut -f2); then
    log "Found matching image ${IMAGE_ID}, skipping"

    return
  fi

  log "Launching bootstrap instance"
  INSTANCE_IDS=($(
    ec2-run-instances $AMI \
      -n 1 \
      --show-empty-fields \
      -k $KEYNAME \
      --instance-type c4.2xlarge \
      --subnet $SUBNET_ID \
      --associate-public-ip-address true |
    grep INSTANCE |
    cut -f2
  ))

  local INSTANCE_ID=$INSTANCE_IDS
  ec2-create-tags ${INSTANCE_ID} -t Name=bootstrap

  wait_until_status "running"
  wait_until_check_ok

  update_software

  log "Stopping bootstrap instance"
  ec2-stop-instances $INSTANCE_ID

  wait_until_status "stopped"

  log "Enabling enhanced networking"
  ec2-modify-instance-attribute $INSTANCE_ID --sriov simple

  IMAGE_ID=$(ec2-create-image --show-empty-fields $INSTANCE_ID --name "$NAME" | cut -f2)
  log "Created image ${IMAGE_ID}"

  log "Terminating bootstrap instance"
  ec2-terminate-instances $INSTANCE_ID

  wait_until_available "$NAME"
}

create_vpc() {
  log "Creating VPC"
  if [[ ! -z $VPC_ID || ! -z $SUBNET_ID ]]; then
    log "VPC_ID and/or SUBNET_ID specified, skipping"

    return
  fi

  VPC_ID=$(ec2-create-vpc "10.0.0.0/16" | cut -f2)

  log "Created VPC ${VPC_ID}"

  GROUP_ID=$(ec2-describe-group | grep $VPC_ID | cut -f2)

  log "Enabling all inbound traffic on security group ${GROUP_ID}"

  ec2-authorize $GROUP_ID -P all

  log "Creating internet gateway"

  IGW_ID=$(ec2-create-internet-gateway | cut -f2)
  log "Attaching gateway ${IGW_ID} to VPC ${VPC_ID}"

  ec2-attach-internet-gateway ${IGW_ID} -c ${VPC_ID}

  RTB_ID=$(ec2-describe-route-tables | grep ${VPC_ID} | cut -f2)

  log "Adding route on ${RTB_ID} to ${IGW_ID}"

  ec2-create-route ${RTB_ID} -g ${IGW_ID} -r "0.0.0.0/0"
}

create_subnet() {
  log "Creating subnet"
  if [[ ! -z $SUBNET_ID ]]; then
    log "SUBNET_ID specified, skipping"

    return
  fi

  SUBNET_ID=$(ec2-create-subnet -c $VPC_ID -i "10.0.0.0/24" | cut -f2)
}

run_instances() {
  log "Starting instances"

  BLOCK_DEV=(/dev/xvd{b..y})
  EPHEMERAL=(ephemeral{0..23})
  MAPPINGS=""
  for I in $(seq 0 23); do
    MAPPINGS+=" --block-device-mapping \"${BLOCK_DEV[$I]}=${EPHEMERAL[$I]}\""
  done

  INSTANCE_IDS=($(
    ec2-run-instances $IMAGE_ID \
      -n $INSTANCES \
      --tenancy ${TENANCY} \
      --show-empty-fields \
      -k $KEYNAME \
      --instance-type $INSTANCE_TYPE \
      --subnet $SUBNET_ID \
      --associate-public-ip-address true \
      ${MAPPINGS} |
    grep INSTANCE |
    cut -f2
  ))

  log "Created instances: ${INSTANCE_IDS[*]}"

  wait_until_status "running"
  wait_until_check_ok
}

update_software() {
  local IPS
  IPS=$(ec2-describe-instances --show-empty-fields ${INSTANCE_IDS[*]} | grep INSTANCE | cut -f17)

  log "Updating software on instances"

  run_updates() {
    local IP=$1

    $SSH_PROXY ssh -i "${AWS_KEYPAIR}" -t -t ${SSH_USER}@${IP} "sudo -u root yum update -y"
    $SSH_PROXY ssh -i "${AWS_KEYPAIR}" -t -t ${SSH_USER}@${IP} "sudo -u root yum install -y xfsprogs mdadm unzip ed ntp postgresql time bc vim"
    $SSH_PROXY ssh -i "${AWS_KEYPAIR}" -t -t ${SSH_USER}@${IP} "sudo -u root yum groupinstall -y 'Development Tools'"
  }

  for IP in $IPS; do
    ssh-keygen -R $IP || true
    ssh-keyscan $IP >> ~/.ssh/known_hosts
  done

  for IP in $IPS; do
    (run_updates $IP) &
  done

  wait
}

set_networking() {
  log "Enabling enhanced networking"

  ec2-stop-instances ${INSTANCE_IDS[*]}

  wait_until_status "stopped"

  for INSTANCE_ID in ${INSTANCE_IDS[*]}; do
    log "Enabling enhanced networking for ${INSTANCE_ID}"

    ec2-modify-instance-attribute $INSTANCE_ID --sriov simple
  done

  ec2-start-instances ${INSTANCE_IDS[*]}

  wait_until_status "running"
  wait_until_check_ok
}

print_addresses() {
  log "Provision complete\n\n"

  log "INSTANCE\tPUBLIC IP\tPRIVATE IP"

  ec2-describe-instances --show-empty-fields ${INSTANCE_IDS[*]} | grep INSTANCE | cut -f2,17,18
}

create_hostfiles() {
  log "Creating hostfiles in directory ${WORK_DIR}"

  local DESCRIPTION
  DESCRIPTION=$(ec2-describe-instances --show-empty-fields ${INSTANCE_IDS[*]} | grep INSTANCE | cut -f17,18 | xargs -n 2)

  local COUNT
  COUNT=$(echo "$DESCRIPTION" | wc -l | xargs)

  local EXTERNAL_IPS
  EXTERNAL_IPS=($(echo "$DESCRIPTION" | cut -d' ' -f1))

  local INTERNAL_IPS
  INTERNAL_IPS=($(echo "$DESCRIPTION" | cut -d' ' -f2))

  > ${WORK_DIR}/external-hosts
  > ${WORK_DIR}/internal-hosts

  J=0
  for I in $(seq 0 $(expr $COUNT - 1)); do
    if [[ $I -eq 0 ]]; then
      echo "${EXTERNAL_IPS[$I]} mdw" >> ${WORK_DIR}/external-hosts
      echo "${INTERNAL_IPS[$I]} mdw" >> ${WORK_DIR}/internal-hosts

      continue
    fi

    if [[ $I -eq 1 ]] && [[ $STANDBY -eq 1 ]]; then
      echo "${EXTERNAL_IPS[$I]} smdw" >> ${WORK_DIR}/external-hosts
      echo "${INTERNAL_IPS[$I]} smdw" >> ${WORK_DIR}/internal-hosts

      continue
    fi

    if [[ $I -ge $(expr 1 + $STANDBY + $SEGMENT_HOSTS) ]]; then
      ETL_NUMBER=$(expr $I - $STANDBY - $SEGMENT_HOSTS)
      echo "${EXTERNAL_IPS[$I]} etl${ETL_NUMBER}" >> ${WORK_DIR}/external-hosts
      echo "${INTERNAL_IPS[$I]} etl${ETL_NUMBER}" >> ${WORK_DIR}/internal-hosts

      continue
    fi

    echo "${EXTERNAL_IPS[$I]} sdw$(expr $I - $STANDBY)" >> ${WORK_DIR}/external-hosts
    echo "${INTERNAL_IPS[$I]} sdw$(expr $I - $STANDBY)" >> ${WORK_DIR}/internal-hosts
  done
}

rename_instances() {
  log "Renaming instances"

  for I in $(seq 0 $(expr ${#INSTANCE_IDS[@]} - 1))
  do
    if [[ $I -eq 0 ]]; then
      ec2-create-tags ${INSTANCE_IDS[$I]} -t Name=mdw

      continue
    fi

    if [[ $I -eq 1 ]] && [[ $STANDBY -eq 1 ]]; then
      ec2-create-tags ${INSTANCE_IDS[$I]} -t Name=smdw

      continue
    fi

    if [[ $I -ge $(expr 1 + $STANDBY + $SEGMENT_HOSTS) ]]; then
      ETL_NUMBER=$(expr $I - $STANDBY - $SEGMENT_HOSTS)
      ec2-create-tags ${INSTANCE_IDS[$I]} -t Name=etl${ETL_NUMBER}

      continue
    fi

    ec2-create-tags ${INSTANCE_IDS[$I]} -t Name=sdw$(expr $I - $STANDBY)
  done
}

wait_until_status() {
  local STATUS=$1

  log "Waiting for status: ${STATUS}"

  local N=0
  until [[ $N -ge $RETRIES ]]; do
    local COUNT=$(
      ec2-describe-instances --show-empty-fields ${INSTANCE_IDS[*]} |
      grep INSTANCE |
      cut -f6 |
      grep -c ${STATUS}
    ) || true

    log "${COUNT} of ${#INSTANCE_IDS[@]} instances ${STATUS}"

    [[ "$COUNT" -eq "${#INSTANCE_IDS[@]}" ]] && break

    N=$(($N+1))
    sleep $WAIT
  done

  if [[ $N -ge $RETRIES ]]; then
    error "Timed out waiting for instances to reach status: ${STATUS}"
  fi
}

wait_until_check_ok() {
  local STATUS=$1

  log "Waiting for instances to pass status checks"

  local N=0
  until [[ $N -ge $RETRIES ]]; do
    local COUNT

    COUNT=$(
      ec2-describe-instance-status --show-empty-fields ${INSTANCE_IDS[*]} |
      grep -e "\bINSTANCE\b" |
      cut -f6,7 |
      xargs -n 2 |
      grep -c "ok ok"
    ) || true

    log "${COUNT} of ${#INSTANCE_IDS[@]} instances pass status checks"

    [[ "$COUNT" -eq "${#INSTANCE_IDS[@]}" ]] && break

    COUNT=$(
      ec2-describe-instance-status --show-empty-fields ${INSTANCE_IDS[*]} |
      grep -e "\bINSTANCE\b" |
      cut -f6,7 |
      xargs -n 2 |
      grep -c "impaired"
    ) || true

    if [[ "$COUNT" -gt 0 ]]; then
      error "${COUNT} of ${#INSTANCE_IDS[@]} failed to pass status checks"
    fi

    N=$(($N+1))
    sleep $WAIT
  done

  if [[ $N -ge $RETRIES ]]; then
    error "Timed out waiting for instances to pass status checks"
  fi
}

wait_until_available() {
  local NAME=$1

  log "Waiting for AMI to become available"

  local N=0
  until [[ $N -ge $RETRIES ]]; do
    local COUNT=$(
      ec2-describe-images --show-empty-fields |
      grep -e "\bIMAGE\b" |
      grep "$NAME" |
      cut -f5 |
      grep -c "available"
    ) || true

    [[ "$COUNT" -eq "1" ]] && break

    echo -n .

    N=$(($N+1))
    sleep $WAIT
  done

  if [[ $N -ge $RETRIES ]]; then
    error "Timed out waiting for AMI to become available"
  fi
}

main "$@"
