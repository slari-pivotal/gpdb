#!/bin/bash -l

set -eox pipefail
CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${CWDIR}/common.bash"
CONCOURSE_DIR="${CWDIR}/../../../../"
export CONCOURSE_DIR=${CONCOURSE_DIR}

function cleanup(){
    export PATH=/usr/bin:$PATH
    export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY"
    export AWS_DEFAULT_REGION="$AWS_REGION"
    mkdir ~/.aws

    cat << CREDENTIALS > ~/.aws/credentials
[default]
aws_access_key_id=${AWS_ACCESS_KEY}
aws_secret_access_key=${AWS_SECRET_KEY}
CREDENTIALS

    cat << CONFIG > ~/.aws/config
[default]
region=${AWS_REGION}
output=json
CONFIG

    ip_list=$(cat ./hostfile/internal-hosts |  xargs -n 2 | cut -f1 -d' ')
    for i in $ip_list; do i_id=`aws ec2 describe-instances --filters "Name=private-ip-address, Values=$i" | grep InstanceId | grep -o "i-\w\+"`; aws ec2 modify-instance-attribute --instance-id $i_id --block-device-mappings "[{\"DeviceName\": \"/dev/sda1\",\"Ebs\":{\"DeleteOnTermination\":true}}]"; done
    for i in $ip_list; do i_id=`aws ec2 describe-instances --filters "Name=private-ip-address, Values=$i" | grep InstanceId | grep -o "i-\w\+"`; aws ec2 terminate-instances --instance-id $i_id; done
}

function _main() {
    cleanup
}

_main "$@"
