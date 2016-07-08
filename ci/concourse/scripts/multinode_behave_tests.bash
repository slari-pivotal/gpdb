#!/bin/bash -l

set -eox pipefail
CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${CWDIR}/common.bash"
CONCOURSE_DIR="${CWDIR}/../../../../"
export CONCOURSE_DIR=${CONCOURSE_DIR}

function prep_hosts(){
    mkdir ~/.ssh

    for IP in $(cat ./hostfile/internal-hosts | cut -d' ' -f1); do
        ssh-keygen -R $IP || true
        ssh-keyscan $IP >> ~/.ssh/known_hosts
    done
}

function echo_keypair(){
    export AWS_KEYPAIR="${CWDIR}/multinode-key.pem"
    echo -n "${PRIVATE_KEY}" > $AWS_KEYPAIR
    chmod 600 $AWS_KEYPAIR
}

function run_tests(){
    MDW_HOST=$(cat ./hostfile/internal-hosts | grep mdw | xargs -n 2 | cut -f1 -d' ')
    ssh -i ${AWS_KEYPAIR} -t centos@${MDW_HOST} " sudo -i -u gpadmin bash -c 'cd /usr/local/greenplum-db/gpMgmt/bin; make behave tags=${BEHAVE_TAGS}'"
}

function _main() {
    prep_hosts
    echo_keypair
    run_tests
}

_main "$@"
