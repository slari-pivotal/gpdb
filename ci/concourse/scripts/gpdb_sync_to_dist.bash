#!/bin/bash -l

set -euo pipefail

function echo_expected_env_variables() {
  echo "Target remote directory: $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIRECTORY"
  echo "Local installer zip: $INSTALLER_ZIP"
  echo "Local source code package: $GPDB_SRC_TAR_GZ"
}

function validate_remote_dir() {
  #To prevent accidental creation of weird directories or arbitrary command
  #execution by the user, we validate the remote directory.
  #For example, paths like "/opt" and "/data/dist/GPDB/../../../opt" are not allowed.
  #grep will fail if the regex does not match and this script will stop due to the set -euo.
  echo -e "Validating that $REMOTE_DIRECTORY is a valid path (must be a" \
          "subdirectory of /data/dist/GPDB)...\c"
  echo "$REMOTE_DIRECTORY" | grep '^/data/dist/GPDB/[/a-zA-Z0-9\-\_]\+$' > /dev/null
  echo " validated"
}

function scp_zip_src() {
  local remote_path
  local ssh_key_file
  remote_path="$REMOTE_DIRECTORY/`basename $INSTALLER_ZIP`"
  ssh_key_file="$(mktemp -t ssh_key)"
  echo "$SSH_KEY" > "$ssh_key_file"

  #We do not use mkdir -p, to prevent the user from accidentally creating random
  #directories on our server. Also, we use StrictHostKeyChecking=no an
  #LogLevel=error to avoid printing warning messages such as "permanently added
  #to the list of known hosts"
  ssh -i $ssh_key_file -o UserKnownHostsFile=/dev/null \
      -o LogLevel=error -o StrictHostKeyChecking=no \
      "$REMOTE_USER@$REMOTE_HOST" "if [ ! -d $REMOTE_DIRECTORY ]; then mkdir $REMOTE_DIRECTORY; fi" > /dev/null

  #scp is not an atomic operation, so we use a scp/ssh mv to avoid broken files
  #being left sitting on the server
  scp -i $ssh_key_file -o UserKnownHostsFile=/dev/null \
      -o LogLevel=error -o StrictHostKeyChecking=no \
      "$INSTALLER_ZIP" "$REMOTE_USER@$REMOTE_HOST:$remote_path.new" > /dev/null
  ssh -i $ssh_key_file -o UserKnownHostsFile=/dev/null \
      -o LogLevel=error -o StrictHostKeyChecking=no \
      "$REMOTE_USER@$REMOTE_HOST" "mv $remote_path.new $remote_path" > /dev/null

  #Upload the packaged source code
  remote_path="$REMOTE_DIRECTORY/`basename $GPDB_SRC_TAR_GZ`"

  scp -i $ssh_key_file -o UserKnownHostsFile=/dev/null \
      -o LogLevel=error -o StrictHostKeyChecking=no \
      "$GPDB_SRC_TAR_GZ" "$REMOTE_USER@$REMOTE_HOST:$remote_path.new" > /dev/null
  ssh -i $ssh_key_file -o UserKnownHostsFile=/dev/null \
      -o LogLevel=error -o StrictHostKeyChecking=no \
      "$REMOTE_USER@$REMOTE_HOST" "mv $remote_path.new $remote_path" > /dev/null
}

function echo_completion() {
  local remote_dir_url=${REMOTE_DIRECTORY:5}
  echo "Uploaded installer file: http://$REMOTE_HOST$remote_dir_url/`basename $INSTALLER_ZIP`"
}

function _main() {
  echo_expected_env_variables

  validate_remote_dir

  scp_zip_src

  echo_completion
}

_main "$@"
