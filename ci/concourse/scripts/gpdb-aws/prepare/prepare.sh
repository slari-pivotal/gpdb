#!/bin/bash

set -e
set -o pipefail
if [[ ! -z "$TRACE" ]]; then
  set -x
fi

BASEDIR=$(cd "${0%/*}"; pwd)

if [[ -z $WORK_DIR ]]; then
  WORK_DIR=${BASEDIR}/.log/$(date +%F)/$(date "+%H%M")
fi

LOGFILE="${WORK_DIR}/$(basename ${BASH_SOURCE[0]} .sh).log"

mkdir -p ${WORK_DIR}

EXTERNAL_HOSTS=$1
INTERNAL_HOSTS=$2

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

if [[ -z "$AWS_KEYPAIR" ]]; then
  error \$AWS_KEYPAIR must be specified
fi

if [[ -z "$EXTERNAL_HOSTS" ]]; then
  error Hostfile must be specified
fi

if [[ -z "$INTERNAL_HOSTS" ]]; then
  log Internal hostfile not specified, using ${EXTERNAL_HOSTS}
  INTERNAL_HOSTS=${EXTERNAL_HOSTS}
fi

if [[ -z "$SSH_USER" ]]; then
  SSH_USER=root
fi

HOSTS=$(cat "$EXTERNAL_HOSTS")
HOSTFILE=$(cat "$INTERNAL_HOSTS")

trap '[[ $? != 0 ]] && log Failed. Run with TRACE=1 to see full output' EXIT

main() {
  log "Setup"

  while read LINE; do
    local IP=$(echo $LINE | cut -d' ' -f1)
    local HOST=$(echo $LINE | cut -d' ' -f2)

    ssh-keygen -R $IP || true
    ssh-keyscan $IP >> ~/.ssh/known_hosts

    (setup_hosts $IP $HOST) &
  done < $EXTERNAL_HOSTS

  wait

  ensure_connectivity

  echo "Logs written to ${LOGFILE}"
}


setup_hosts() {
  local IP=$1
  local HOST=$2

  local EXPORTS="
export TRACE=\"$TRACE\"
export HOSTFILE=\"$HOSTFILE\"
export HOST=\"$HOST\"
"
  log "Setting up $HOST ($IP)"

  for S in ${BASEDIR}/??_*.sh; do
    echo -e "$EXPORTS;\n$(cat "$S");\nexit" | $SSH_PROXY ssh -i "${AWS_KEYPAIR}" -t -t ${SSH_USER}@${IP} 'sudo -u root bash -s' 2>&1
  done
}

ensure_connectivity() {
  local ROOT_KEYS=""
  local GPADMIN_KEYS=""

  while read -u 3 LINE; do
    local IP=$(echo $LINE | cut -d' ' -f1)

    ROOT_KEYS+="$($SSH_PROXY ssh -i "${AWS_KEYPAIR}" -t ${SSH_USER}@${IP} 'sudo -u root cat ~root/.ssh/id_rsa.pub')\n"
    GPADMIN_KEYS+="$($SSH_PROXY ssh -i "${AWS_KEYPAIR}" -t ${SSH_USER}@${IP} 'sudo -u gpadmin cat ~gpadmin/.ssh/id_rsa.pub')\n"
  done 3< $EXTERNAL_HOSTS

  while read -u 3 LINE; do
    local IP=$(echo $LINE | cut -d' ' -f1)

    $SSH_PROXY ssh -i "${AWS_KEYPAIR}" -t ${SSH_USER}@${IP} "sudo -u root echo -e \"$ROOT_KEYS\" >> ~root/.ssh/authorized_keys"
    $SSH_PROXY ssh -i "${AWS_KEYPAIR}" -t ${SSH_USER}@${IP} "sudo -u gpadmin echo -e \"$GPADMIN_KEYS\" >> ~gpadmin/.ssh/authorized_keys"
  done 3< $EXTERNAL_HOSTS
}


main "$@"
