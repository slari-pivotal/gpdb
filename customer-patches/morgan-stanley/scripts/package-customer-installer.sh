#!/bin/bash
set -xe

BASE_DIR=`pwd`
# TODO: USE "REAL" release here before merging
RELEASE=`${BASE_DIR}/gpdb_src/getversion --short`
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

GPDB_INSTALLER_FILE="greenplum-db-${RELEASE}-rhel5-x86_64.zip"

TESTED_BIN_GDPB="bin_gpdb/bin_gpdb.tar.gz"

## ----------------------------------------------------------------------
## Assemble GPDB installer
## ----------------------------------------------------------------------
echo ""
echo "----------------------------------------------------------------------"
echo "Create updated installer bin file"
echo "----------------------------------------------------------------------"

rm -f /tmp/header-gpdb-*
sed -e "s/%RELEASE%/${RELEASE}/g" $SCRIPT_DIR/header-gpdb-template.txt > /tmp/header-gpdb-$$.txt
cat /tmp/header-gpdb-$$.txt $TESTED_BIN_GDPB > $( basename ${GPDB_INSTALLER_FILE} .zip ).bin
chmod a+x $( basename ${GPDB_INSTALLER_FILE} .zip ).bin

echo ""
echo "----------------------------------------------------------------------"
echo "Update original installer zip file with new installer"
echo "----------------------------------------------------------------------"
echo ""

zip $( basename ${GPDB_INSTALLER_FILE} ) -u $( basename ${GPDB_INSTALLER_FILE} .zip ).bin

openssl dgst -sha256 $( basename ${GPDB_INSTALLER_FILE} ) > $( basename ${GPDB_INSTALLER_FILE} ).sha256

echo ""
echo "----------------------------------------------------------------------"
echo "Done baking:"
echo "  $( ls -l $( basename ${GPDB_INSTALLER_FILE} )) "
echo "  $( ls -l $( basename ${GPDB_INSTALLER_FILE} )).sha256 "
echo "----------------------------------------------------------------------"

mkdir -p $BASE_DIR/ms_installer_rhel5_gpdb_rc
cp greenplum-db-${RELEASE}-rhel5-x86_64.zip $BASE_DIR/ms_installer_rhel5_gpdb_rc/
cp greenplum-db-${RELEASE}-rhel5-x86_64.zip.sha256 $BASE_DIR/ms_installer_rhel5_gpdb_rc/
