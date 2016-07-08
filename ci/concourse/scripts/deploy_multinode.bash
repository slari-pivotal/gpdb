#!/bin/bash -l

set -eox pipefail
CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${CWDIR}/common.bash"
CONCOURSE_DIR="${CWDIR}/../../../../"
export CONCOURSE_DIR=${CONCOURSE_DIR}
# Assume we only grab a single zip file
INSTALLER_ZIP=$(cd installer_rhel5_gpdb; ls greenplum-db-*-*-x86_64.zip)

function install_aws_tools() {
    pushd /tmp
        wget http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip
        unzip ec2-api-tools.zip
        mv ec2-api-tools-* /usr/local/bin/ec2-api-tools
        export PATH=/usr/local/bin/ec2-api-tools/bin/:$PATH
        export EC2_HOME=/usr/local/bin/ec2-api-tools
    popd
}

function setup_multinode_cluster() {
    pushd "${CWDIR}/gpdb-aws"
        export AWS_KEYPAIR="${CWDIR}/multinode-key.pem"
        echo -n "${PRIVATE_KEY}" > $AWS_KEYPAIR
        chmod 600 $AWS_KEYPAIR
        INSTALLER_BIN=${INSTALLER_ZIP%.zip}.bin
        GREENPLUM_DB="${CONCOURSE_DIR}/${GPDB_INSTALLER_DIR}/${INSTALLER_BIN}" \
        ./setup.sh 2
        WORK_DIR="/root/.gpcloud/`ls /root/.gpcloud/ | head -1`"
        MDW_HOST=$(cat ${WORK_DIR}/external-hosts | grep mdw | xargs -n 2 | cut -f1 -d' ')
        ssh -i ${AWS_KEYPAIR} centos@${MDW_HOST} "sudo -u gpadmin bash -c \"echo export MDW_HOST=${MDW_HOST} >> /home/gpadmin/.bashrc\""
        ssh -i ${AWS_KEYPAIR} centos@${MDW_HOST} 'sudo -u gpadmin sed -i "/MASTER_DATA_DIRECTORY/c\export MASTER_DATA_DIRECTORY=/data1/master/gpseg-1" /home/gpadmin/.bashrc'
        ssh -i ${AWS_KEYPAIR} centos@${MDW_HOST} 'sudo -u gpadmin bash -c "echo export PGPORT=5432 >> /home/gpadmin/.bashrc"'
    popd
}

function scp_gpdb_source() {
    tar -cvf ${CONCOURSE_DIR}/gpdb_src/gpMgmt.tar -C ${CONCOURSE_DIR}/gpdb_src/ gpMgmt
    scp -r -i ${AWS_KEYPAIR} ${CONCOURSE_DIR}/gpdb_src/gpMgmt.tar centos@${MDW_HOST}:/tmp
    ssh -i ${AWS_KEYPAIR} -t centos@${MDW_HOST} 'sudo -u gpadmin tar -xvf /tmp/gpMgmt.tar -C /usr/local/greenplum-db'
}

function run_tests(){
    ssh -i ${AWS_KEYPAIR} -t centos@${MDW_HOST} " sudo -i -u gpadmin bash -c 'cd /usr/local/greenplum-db/gpMgmt/bin; make behave tags=${BEHAVE_TAGS}'"
}

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

    ip_list=$(cat ${WORK_DIR}/internal-hosts |  xargs -n 2 | cut -f1 -d' ')
    for i in $ip_list; do i_id=`aws ec2 describe-instances --filters "Name=private-ip-address, Values=$i" | grep InstanceId | grep -o "i-\w\+"`; aws ec2 modify-instance-attribute --instance-id $i_id --block-device-mappings "[{\"DeviceName\": \"/dev/sda1\",\"Ebs\":{\"DeleteOnTermination\":true}}]"; done
    for i in $ip_list; do i_id=`aws ec2 describe-instances --filters "Name=private-ip-address, Values=$i" | grep InstanceId | grep -o "i-\w\+"`; aws ec2 terminate-instances --instance-id $i_id; done
}

function unzip_gpdb(){
    pushd installer_rhel5_gpdb
        unzip ${INSTALLER_ZIP}
    popd
}

function move_hostfiles(){
    cp ${WORK_DIR}/internal-hosts ./hostfile/internal-hosts
}

function _main() {
    time install_gpdb
    ./gpdb_src/ci/concourse/scripts/setup_gpadmin_user.bash "$TEST_OS"
    unzip_gpdb

    install_aws_tools
    setup_multinode_cluster
    scp_gpdb_source
    move_hostfiles
}

_main "$@"
