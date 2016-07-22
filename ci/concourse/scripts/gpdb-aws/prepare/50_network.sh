#!/bin/bash

set -e
if [[ ! -z "$TRACE" ]]; then
  set -x
fi

if [ -z "$HOSTFILE" ]; then
  echo '$HOSTFILE' is not set
  exit 1
fi
HOSTFILE_HEAD="# BEGIN GENERATED CONTENT"
HOSTFILE_TAIL="# END GENERATED CONTENT"

main() {
  echo Network

  sed -i -e "/$HOSTFILE_HEAD/,/$HOSTFILE_TAIL/d" /etc/hosts
  echo "$HOSTFILE_HEAD" >> /etc/hosts
  echo "$HOSTFILE" >> /etc/hosts
  echo "$HOSTFILE_TAIL" >> /etc/hosts

  update_known_hosts
}

update_known_hosts() {
  echo "$HOSTFILE" | while read LINE; do
    HOST=$(echo $LINE | cut -d' ' -f2)

    for U in root gpadmin; do
      su $U -c "ssh-keygen -R $HOST" || true

      su $U -c "ssh-keyscan $HOST >> ~/.ssh/known_hosts"

      su $U -c "rm -f ~/.ssh/known_hosts.old"
    done
  done
}

main "$@"
