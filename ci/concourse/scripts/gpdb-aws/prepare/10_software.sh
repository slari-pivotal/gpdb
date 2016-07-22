#!/bin/bash

set -e
if [[ ! -z "$TRACE" ]]; then
  set -x
fi

main() {
  echo Software

  yum update -y
  yum install -y xfsprogs mdadm unzip ed ntp postgresql time bc vim
  yum groupinstall -y "Development Tools"
}

main "$@"

