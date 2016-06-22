#!/bin/bash

set -euo pipefail

main() {
  ABS_PATH_OUTPUT_TARBALL="$(pwd)/$OUTPUT_TARBALL"
  ABS_PATH_FILES_TO_REMOVE_LISTING="$(pwd)/$FILES_TO_REMOVE_LISTING"

  INTERMEDIATE_PLACE="$(mktemp -d)"
  tar zxf "$INPUT_TARBALL" -C "$INTERMEDIATE_PLACE"

  pushd $INTERMEDIATE_PLACE
    echo "Removing files listed in $FILES_TO_REMOVE_LISTING"
    while read file; do
      echo "Removing $file"
      rm -f "$file"
    done < "$ABS_PATH_FILES_TO_REMOVE_LISTING"
    tar czf "$ABS_PATH_OUTPUT_TARBALL" *
  popd
}

main "$@"
