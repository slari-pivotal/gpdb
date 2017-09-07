#!/bin/sh

# this file should be run as "gpadmin" user

set -e

SINGLE_QUOTED_IVY_PASSWORD=$1


mkdir -p ~/.ssh

rm -rf $HOME/.ssh/id_rsa
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa

cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

#the below echo uses multiple lines
echo 'host *
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
' > /home/gpadmin/.ssh/config

chmod 700 /home/gpadmin/.ssh
chmod og-wx ~/.ssh/authorized_keys
chmod 600 ~/.ssh/config

#Configure environment and pull libraries
#the below echo uses multiple lines
echo "
#for gpdb4 compilation
export JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk.x86_64
export PATH=\${JAVA_HOME}/bin:\${PATH}
export IVYREPO_HOST=repo.pivotal.io
export IVYREPO_REALM=\"Artifactory Realm\"
export IVYREPO_USER=build_readonly
export IVYREPO_PASSWD=\"$SINGLE_QUOTED_IVY_PASSWORD\"
export PYTHONPATH=/opt/python-2.6.9/lib/python2.6:\$PYTHONPATH
export PYTHONHOME=/opt/python-2.6.9
export GOPATH=/home/gpadmin/go/docker:/home/gpadmin/go
export PATH=/opt/python-2.6.9/bin:\$PATH
export PATH=/usr/local/go/bin:/home/gpadmin/go/docker/bin:$PATH

" >> ~/.bashrc


source ~/.bashrc
echo '
source /usr/local/greenplum-db-devel/greenplum_path.sh
source ~/gpdemo/gpdemo-env.sh
' >> ~/.bashrc
cd ~/gpdb4_mount/gpAux
rm -f /opt/python-2.6.9
ln -s "/home/gpadmin/gpdb4_mount/gpAux/ext/rhel5_x86_64/python-2.6.9" /opt

set +e
# We don't want to fail if clean has nothing to do
make clean distclean
set -e

make IVYREPO_HOST="$IVYREPO_HOST" \'IVYREPO_REALM="$IVYREPO_REALM"\' IVYREPO_USER="$IVYREPO_USER" IVYREPO_PASSWD="$IVYREPO_PASSWD" sync_tools

#=========================================================
# Give parent script a chance to save container
exit
