#!/bin/bash -l

set -euo pipefail

function echo_expected_env_variables() {
  echo "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIRECTORY"
  echo "$INSTALLER_ZIP"
}

function _main() {
  echo_expected_env_variables
  local filename
  local remote_path
  local ssh_key_file
  filename="$(basename $INSTALLER_ZIP)"
  remote_path="$REMOTE_DIRECTORY/$filename"
  ssh_key_file="$(mktemp -t ssh_key)"
  echo "$SSH_KEY" > "$ssh_key_file"
  scp -i $ssh_key_file -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$INSTALLER_ZIP" "$REMOTE_USER@$REMOTE_HOST:$remote_path.new"
  ssh -i $ssh_key_file -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" "mv $remote_path.new $remote_path"
}

_main "$@"
