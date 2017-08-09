#!/bin/bash

echo root:root | chpasswd
useradd gpadmin
echo gpadmin:gpadmin | chpasswd
mkdir -p /home/gpadmin/gpconfigs && chown gpadmin:gpadmin -R /home/gpadmin/gpconfigs && \
mkdir -p /home/gpadmin/data/master && chown gpadmin:gpadmin -R /home/gpadmin/data && \
mkdir -p /home/gpadmin/data1/primary && chown gpadmin:gpadmin -R /home/gpadmin/data1 && \
mkdir -p /usr/local/greenplum-db-devel && chown gpadmin:gpadmin -R /usr/local/greenplum-db-devel
echo "gpadmin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

#set up bash options
cp ~/{.bashrc,.bash_profile} /home/gpadmin/
#chown on mounted files in gpdb4 is not supported, so chown only the folder and hidden files
chown gpadmin:gpadmin /home/gpadmin
chown gpadmin:gpadmin /home/gpadmin/.bash*
chmod 777 /opt
chmod 777 /usr/local

chown -R gpadmin.gpadmin /opt/releng
chkconfig sshd on
echo "/sbin/service sshd start" >> /root/.bashrc
/sbin/service sshd start

echo "su - gpadmin" >> /root/.bashrc
yum -y install vim-enhanced
