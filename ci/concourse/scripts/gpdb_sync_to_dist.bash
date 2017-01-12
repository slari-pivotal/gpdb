#!/bin/bash -l

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REMOTE_USER="build"
REMOTE_HOST="artifacts.ci.eng.pivotal.io"
REMOTE_DIRECTORY="/data/dist/GPDB/builds_from_concourse/$BUCKET_NAME"

substitute_GP_VERSION() {
  GP_VERSION=$("$DIR/../../../getversion" --short)
  FILE_TO_UPLOAD=${FILE_TO_UPLOAD//@GP_VERSION@/${GP_VERSION}}
}

echo_paths() {
  echo "Target remote directory: $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIRECTORY"
  echo "Local file to upload: $FILE_TO_UPLOAD"
}

validate_remote_dir() {
  # To prevent accidental creation of weird directories or arbitrary command
  # execution by the user, we validate the remote directory.
  # For example, paths like "/opt" and "/data/dist/GPDB/../../../opt" are not allowed.
  # grep will fail if the regex does not match and this script will stop due to the set -euo.
  echo -e "Validating that $REMOTE_DIRECTORY is a valid path (must be a" \
          "subdirectory of /data/dist/GPDB)...\c"
  echo "$REMOTE_DIRECTORY" | grep '^/data/dist/GPDB/[/a-zA-Z0-9\_\.-]\+$' > /dev/null
  echo " validated"
}

scp_zip_src() {
  local remote_path
  local ssh_key_file
  remote_path="$REMOTE_DIRECTORY/$(basename "$FILE_TO_UPLOAD")"
  ssh_key_file="$(mktemp -t ssh_key.XXXXX)"
  echo "$SSH_KEY" > "$ssh_key_file"

  # We do not use mkdir -p in order to prevent the user from accidentally creating
  # random directories on our server. Also, we use StrictHostKeyChecking=no and
  # LogLevel=error to avoid printing warning messages such as "permanently added
  # to the list of known hosts"
  ssh -i "$ssh_key_file" -o UserKnownHostsFile=/dev/null \
      -o LogLevel=error -o StrictHostKeyChecking=no \
      "$REMOTE_USER@$REMOTE_HOST" "if [ ! -d $REMOTE_DIRECTORY ]; then mkdir $REMOTE_DIRECTORY; fi" > /dev/null

  # scp is not an atomic operation, so we use a scp/ssh mv to avoid broken files
  # being left sitting on the server
  scp -i "$ssh_key_file" -o UserKnownHostsFile=/dev/null \
      -o LogLevel=error -o StrictHostKeyChecking=no \
      "$FILE_TO_UPLOAD" "$REMOTE_USER@$REMOTE_HOST:$remote_path.new" > /dev/null
  ssh -i "$ssh_key_file" -o UserKnownHostsFile=/dev/null \
      -o LogLevel=error -o StrictHostKeyChecking=no \
      "$REMOTE_USER@$REMOTE_HOST" "mv $remote_path.new $remote_path" > /dev/null
}

echo_completion() {
  # Remove '/data' off of the remote directory as not present in the URL
  local remote_dir_url=${REMOTE_DIRECTORY:5}
  # artifacts and artifacts-cache are mirrored, but we show the user
  # artifacts-cache as it is faster to access on the network
  local remote_host_cache
  remote_host_cache=$(echo $REMOTE_HOST | sed 's/^artifacts[.]/artifacts-cache./')

  echo "Uploaded file: http://${remote_host_cache}${remote_dir_url}/$(basename "$FILE_TO_UPLOAD")"
}

_main() {
  substitute_GP_VERSION
  echo_paths
  validate_remote_dir
  scp_zip_src
  echo_completion
}

_main "$@"
