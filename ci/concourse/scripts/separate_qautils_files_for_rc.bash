#!/bin/bash

set -euo pipefail

main() {
  ABS_PATH_OUTPUT_TARBALL="$(pwd)/$OUTPUT_TARBALL"
  ABS_QAUTILS_FILES="$(pwd)/$QAUTILS_FILES"
  ABS_PATH_QAUTILS_TARBALL="$(pwd)/$QAUTILS_TARBALL"
  QAUTILS_DIR="$(mktemp -d)"

  INTERMEDIATE_PLACE="$(mktemp -d)"
  tar zxf "$INPUT_TARBALL" -C "$INTERMEDIATE_PLACE"

  pushd "$INTERMEDIATE_PLACE"
    echo "Move files listed in $ABS_QAUTILS_FILES"
    while read file; do
      if [ -f "$file" ]; then
	echo "Moving $file to directory $QAUTILS_DIR"
	mv "$file" "$QAUTILS_DIR"
      else
	echo "File $file does not exists, skipping moving it"
      fi
    done < "$ABS_QAUTILS_FILES"
    tar czf "$ABS_PATH_OUTPUT_TARBALL" *
  popd

  pushd "$QAUTILS_DIR"
    tar czf "$ABS_PATH_QAUTILS_TARBALL" *
  popd
}

main "$@"
