#!/bin/bash

set -e
if [[ ! -z "$TRACE" ]]; then
  set -x
fi

SELINUX="
SELINUX=disabled
"

LIMITS="
* soft nofile 65536
* hard nofile 65536
* soft nproc 131072
* hard nproc 131072
"

main() {
  echo Security

  echo "$LIMITS" > /etc/security/limits.d/99_overrides.conf
  echo "$SELINUX" > /etc/selinux/config

  disable_iptables

  create_gpadmin

  generate_keys
}

disable_iptables() {
  /sbin/service iptables stop
  /sbin/chkconfig iptables off
}

create_gpadmin() {
  getent passwd gpadmin || useradd -m gpadmin
}

generate_keys() {
  echo "STARTED GENERATE_KEYS ID100"
  for U in root gpadmin; do
    echo "LOOP GENERATE_KEYS ID200 ${U}"
    su $U -c "mkdir -p ~${U}/.ssh"
    su $U -c "[[ -f ~${U}/.ssh/id_rsa ]] || ssh-keygen -N '' -f ~${U}/.ssh/id_rsa"

    su $U -c "touch ~${U}/.ssh/authorized_keys"
    su $U -c "chmod 600 ~${U}/.ssh/authorized_keys"
  done
}

main "$@"
