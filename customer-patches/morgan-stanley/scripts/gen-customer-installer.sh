#!/bin/bash
set -xe

## ----------------------------------------------------------------------

GPDB_INSTALLDIR=greenplum-db
CLIENTS_INSTALLDIR=greenplum-clients

## ----------------------------------------------------------------------
## Extract GPPKG contents
## ----------------------------------------------------------------------

extract_std_gppkg(){

    GPPKG_URL=$1
    DEPS=false
    GPPKG=$( basename ${GPPKG_URL} )
    echo ""
    echo "----------------------------------------------------------------------"
    echo "GPPKG extraction: ${GPPKG}"
    echo "----------------------------------------------------------------------"
    echo ""
    if [ ! -f $1 ]; then
      echo "File does not exists"
      exit 1
    fi
    cp $1 .

    TAR_CONTENT=`tar tvf ${GPPKG} *.rpm`
    if [[ $TAR_CONTENT == *"deps/"* ]]; then
        DEPS=true
    fi
    BASE_RPM=$( tar tvf ${GPPKG} *.rpm | grep -v deps | awk '{print $NF}' )

    tar xf ${GPPKG} ${BASE_RPM}
    if [ $? != 0 ]; then
        echo "FATAL: tar extraction failed."
        exit 1
    fi

    rm -rf deps temp $( basename ${BASE_RPM} .rpm )

    rpm2cpio ${BASE_RPM} | cpio -idm

    rm -f ${BASE_RPM}

    if [ ${DEPS} = "true" ]; then
        RPM=$( tar tvf ${GPPKG} *.rpm | grep -e "deps/.*.rpm" | awk '{print $NF}' )
        tar xf ${GPPKG} ${RPM}
        rpm2cpio ${RPM} | cpio -idm

    fi

    mv temp $( basename ${BASE_RPM} .rpm )
    rm -rf deps

    rsync -au $( basename ${BASE_RPM} .rpm )/* ${GPDB_INSTALLDIR}
}

## ======================================================================

BASE_DIR=`pwd`
RELEASE=`${BASE_DIR}/gpdb_src/getversion --short`
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "${GPMT_FILE}" ]; then
    GPMT_FILE=$(echo ${BASE_DIR}/gpmt_binary/gpmt.gz)
fi

if [ -z "${GPSUPPORT_FILE}" ]; then
    GPSUPPORT_FILE=$(echo ${BASE_DIR}/gpsupport_package/gpsupport-1.2.0.0.gz)
fi

if [ -z "${JDBC_DRIVER_FILE}" ]; then
    JDBC_DRIVER_FILE=$(echo ${BASE_DIR}/greenplum_jdbc_zip/greenplum_jdbc_5.1.1.zip)
fi

if [ -z "${MADLIB_GPPKG_FILE}" ]; then
    MADLIB_GPPKG_FILE=$(echo ${BASE_DIR}/madlib_rhel5_gppkg/madlib-*-rhel5-x86_64.gppkg)
fi

if [ -z "${PLJAVA_GPPKG_FILE}" ]; then
    PLJAVA_GPPKG_FILE=$(echo ${BASE_DIR}/pljava_rhel5_gppkg/pljava-*-rhel5-x86_64.gppkg)
fi

if [ -z "${PLR_GPPKG_FILE}" ]; then
    PLR_GPPKG_FILE=$(echo ${BASE_DIR}/plr_rhel5_gppkg/plr-*-rhel5-x86_64.gppkg)
fi

if [ -z "${LOADERS_INSTALLER_FILE}" ]; then
    LOADERS_INSTALLER_FILE=$(echo ${BASE_DIR}/installer_rhel5_gpdb_loaders/greenplum-loaders-${RELEASE}-build-1-rhel5-x86_64.zip)
fi

if [ -z "${CLIENTS_INSTALLER_FILE}" ]; then
    CLIENTS_INSTALLER_FILE=$(echo ${BASE_DIR}/installer_rhel5_gpdb_clients/greenplum-clients-${RELEASE}-build-1-rhel5-x86_64.zip)
fi

if [ -z "${GPDB_INSTALLER_FILE}" ]; then
    GPDB_INSTALLER_FILE=$(echo ${BASE_DIR}/installer_rhel5_gpdb_rc/greenplum-db-${RELEASE}-rhel5-x86_64.zip)
fi

if [ -z "${CONN_INSTALLER_FILE}" ]; then
    CONN_INSTALLER_FILE=$(echo ${BASE_DIR}/installer_rhel5_gpdb_connectivity/greenplum-connectivity-${RELEASE}-build-1-rhel5-x86_64.zip)
fi

if [ -z "${PGCRYPTO_GPPKG_FILE}" ]; then
    PGCRYPTO_GPPKG_FILE=$(echo ${BASE_DIR}/pgcrypto_rhel5_gppkg/pgcrypto-*-rhel5-x86_64.gppkg)
fi

if [ -z "${QAUTILS_FILE}" ]; then
    QAUTILS_FILE=$(echo ${BASE_DIR}/qautils_rhel5_tarball/QAUtils-rhel5-x86_64.tar.gz)
fi

cat <<-EOF
======================================================================
TIMESTAMP ..... : $(date)
----------------------------------------------------------------------

  RELEASE .................. : ${RELEASE}

  GPDB_INSTALLER_FILE ....... : ${GPDB_INSTALLER_FILE}
  CONN_INSTALLER_FILE ....... : ${CONN_INSTALLER_FILE}
  CLIENTS_INSTALLER_FILE .... : ${CLIENTS_INSTALLER_FILE}
  LOADERS_INSTALLER_FILE .... : ${LOADERS_INSTALLER_FILE}
  QAUTILS_FILE .............. : ${QAUTILS_FILE}
  PGCRYPTO_GPPKG_FILE ....... : ${PGCRYPTO_GPPKG_FILE}
  PLR_GPPKG_FILE ............ : ${PLR_GPPKG_FILE}
  PLJAVA_GPPKG_FILE ......... : ${PLJAVA_GPPKG_FILE}
  MADLIB_GPPKG_FILE ......... : ${MADLIB_GPPKG_FILE}
  JDBC_DRIVER_FILE .......... : ${JDBC_DRIVER_FILE}
  GPSUPPORT_FILE ............ : ${GPSUPPORT_FILE}

======================================================================
EOF

pushd $SCRIPT_DIR
mkdir -p build
pushd build

mkdir -p ${GPDB_INSTALLDIR} ${CLIENTS_INSTALLDIR}

## ----------------------------------------------------------------------
## Retrieve and Extract GPDB installer
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "Retrieve installer: $( basename ${GPDB_INSTALLER_FILE} )"
echo "----------------------------------------------------------------------"
echo ""

cp ${GPDB_INSTALLER_FILE} .
GPDB_BIN=$( basename ${GPDB_INSTALLER_FILE} .zip ).bin
unzip $( basename ${GPDB_INSTALLER_FILE} ) ${GPDB_BIN}
cp $( basename ${GPDB_INSTALLER_FILE} ) $( basename ${GPDB_INSTALLER_FILE} ).orig

## Retrieve installer shell script header
SKIP=$(awk '/^__END_HEADER__/ {print NR + 1; exit 0; }'  ${GPDB_BIN})
head -$( expr ${SKIP} - 1 ) ${GPDB_BIN} > header-gpdb.txt

## Extract installer payload (compressed tarball)
tail -n +${SKIP} ${GPDB_BIN} | tar zvxf - -C ${GPDB_INSTALLDIR}

## Save original installer
mv ${GPDB_BIN} ${GPDB_BIN}.orig

## ----------------------------------------------------------------------
## Process GPPKGS
## ----------------------------------------------------------------------

extract_std_gppkg ${PLJAVA_GPPKG_FILE}

extract_std_gppkg ${PGCRYPTO_GPPKG_FILE}

extract_std_gppkg ${PLR_GPPKG_FILE}

echo ""
echo "Update greenplum_path.sh"

echo '' >> ${GPDB_INSTALLDIR}/greenplum_path.sh
echo 'export R_HOME=$GPHOME/ext/R-3.1.0/lib64/R' >> ${GPDB_INSTALLDIR}/greenplum_path.sh


echo 'export LD_LIBRARY_PATH=$GPHOME/ext/R-3.1.0/lib64/R/lib:$LD_LIBRARY_PATH' >> ${GPDB_INSTALLDIR}/greenplum_path.sh

## ----------------------------------------------------------------------
## Process Alpine
## ----------------------------------------------------------------------

echo ""
echo "Include Alpine"

rsync -auv --exclude=src ../../alpine ${GPDB_INSTALLDIR}/ext
cp -v ${GPDB_INSTALLDIR}/ext/alpine/sharedLib/4.3.5/alpine_miner.centos_64bit.so ${GPDB_INSTALLDIR}/lib/postgresql/alpine_miner.so

chmod 755 ${GPDB_INSTALLDIR}/lib/postgresql/alpine_miner.so ${GPDB_INSTALLDIR}/ext/alpine/sharedLib/4.3.5/alpine_miner.centos_64bit.so

pushd ${GPDB_INSTALLDIR}/ext/alpine/sharedLib/4.3.5
ln -sf alpine_miner.centos_64bit.so alpine_miner.so
popd

## ----------------------------------------------------------------------
## Process MADlib
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "MADlib extraction: $( basename ${MADLIB_GPPKG_FILE} )"
echo "----------------------------------------------------------------------"
echo ""

mkdir madlib_temp
pushd madlib_temp > /dev/null

cp ${MADLIB_GPPKG_FILE} .
tar zxf $( basename ${MADLIB_GPPKG_FILE} )

rpm2cpio *.rpm | cpio -idm

get_madlib_version() {
  # capture 1.9 out of ...madlib-ossv1.9_pv1.9.5... (or similar)
  echo "$MADLIB_GPPKG_FILE" | sed -n 's/.*madlib-ossv\(.*\)_pv.*/\1/p'
}

pushd usr/local/madlib > /dev/null
ln -s "Versions/$(get_madlib_version)" Current
ln -s Current/bin bin
ln -s Current/doc doc
popd > /dev/null

mv usr/local/madlib ../greenplum-db
mv *.gppkg ..

popd > /dev/null

rm -rf madlib_temp

## ----------------------------------------------------------------------
## Process gpsupport
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "GPSupport retrieval: $( basename ${GPSUPPORT_FILE} )"
echo "----------------------------------------------------------------------"

cp ${GPSUPPORT_FILE} ${GPDB_INSTALLDIR}/bin/gpsupport.gz
gunzip ${GPDB_INSTALLDIR}/bin/gpsupport.gz

chmod a+x ${GPDB_INSTALLDIR}/bin/gpsupport

## ----------------------------------------------------------------------
## Process gpmt
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "GPMT retrieval: $( basename ${GPMT_FILE} )"
echo "----------------------------------------------------------------------"

cp ${GPMT_FILE} ${GPDB_INSTALLDIR}/bin/gpmt.gz
gunzip ${GPDB_INSTALLDIR}/bin/gpmt.gz
chmod a+x ${GPDB_INSTALLDIR}/bin/gpmt

## ----------------------------------------------------------------------
## Process gpcheckmirrorseg.pl
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "QAUtils retrieval: $( basename ${QAUTILS_FILE} )"
echo "----------------------------------------------------------------------"

cp ${QAUTILS_FILE} .
pushd ${GPDB_INSTALLDIR} > /dev/null
tar zxf ../$( basename ${QAUTILS_FILE} ) bin/gpcheckmirrorseg.pl
popd > /dev/null

## ----------------------------------------------------------------------
## Retrieve and Extract CONN installer
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "Retrieve installer: $( basename ${CONN_INSTALLER_FILE} )"
echo "----------------------------------------------------------------------"
echo ""

rm -f $( basename ${CONN_INSTALLER_FILE} ) $( basename ${CONN_INSTALLER_FILE} .zip ).bin

cp ${CONN_INSTALLER_FILE} .
CONN_BIN=$( basename ${CONN_INSTALLER_FILE} .zip ).bin
unzip $( basename ${CONN_INSTALLER_FILE} ) ${CONN_BIN}
cp $( basename ${CONN_INSTALLER_FILE} ) $( basename ${CONN_INSTALLER_FILE} ).orig

## Retrieve installer shell script header
SKIP=$(awk '/^__END_HEADER__/ {print NR + 1; exit 0; }'  ${CONN_BIN})
head -$( expr ${SKIP} - 1 ) ${CONN_BIN} > header-conn.txt

## Extract installer payload (compressed tarball)
tail -n +${SKIP} ${CONN_BIN} | tar zxf - -C ${GPDB_INSTALLDIR}

## Save original installer
mv ${CONN_BIN} ${CONN_BIN}.orig

## ----------------------------------------------------------------------
## Process JDBC Driver
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "JDBC Driver extraction: $( basename ${JDBC_DRIVER_FILE} )"
echo "----------------------------------------------------------------------"
echo ""

cp ${JDBC_DRIVER_FILE} .
unzip $( basename ${JDBC_DRIVER_FILE} )
if [ $? != 0 ]; then
    echo "FATAL: unzip failed."
    exit 1
fi

mkdir -p ${GPDB_INSTALLDIR}/drivers/jdbc/$( basename ${JDBC_DRIVER_FILE} .zip )
mv greenplum.jar ${GPDB_INSTALLDIR}/drivers/jdbc/$( basename ${JDBC_DRIVER_FILE} .zip )

## ----------------------------------------------------------------------
## Update KRB5
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "Update KRB5"
echo "----------------------------------------------------------------------"
echo ""

LIB_LIST="krb5-1.6.2"

for i in ${LIB_LIST}; do
    for i in `cat $SCRIPT_DIR/checksums.$i | awk '{print $2}'`; do
		if [ -f ${GPDB_INSTALLDIR}/$i ]; then
        	rm -fv ${GPDB_INSTALLDIR}/$i
		fi
    done
done

rm -rf krb5-rhel55_x86_64-1.13.targz
cp $BASE_DIR/mit_krb5_rhel62_tarball/krb5-rhel62_x86_64-1.13.targz .
rm -rf rhel62_x86_64
tar xf krb5-rhel62_x86_64-1.13.targz
rsync -au rhel62_x86_64/lib/* ${GPDB_INSTALLDIR}/lib

## ----------------------------------------------------------------------
## Assemble GPDB installer
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "Create updated installer payload (compressed tarball)"
echo "----------------------------------------------------------------------"

pushd ${GPDB_INSTALLDIR} > /dev/null
tar zcf ../$( basename ${GPDB_INSTALLER_FILE} .zip ).tgz *
popd > /dev/null

echo ""
echo "----------------------------------------------------------------------"
echo "Create updated installer bin file"
echo "----------------------------------------------------------------------"

rm -f /tmp/header-gpdb-*
sed -e "s/%RELEASE%/${RELEASE}/g" $SCRIPT_DIR/header-gpdb-template.txt > /tmp/header-gpdb-$$.txt
cat /tmp/header-gpdb-$$.txt $( basename ${GPDB_INSTALLER_FILE} .zip ).tgz > $( basename ${GPDB_INSTALLER_FILE} .zip ).bin
chmod a+x $( basename ${GPDB_INSTALLER_FILE} .zip ).bin

echo ""
echo "----------------------------------------------------------------------"
echo "Update original installer zip file with new installer"
echo "----------------------------------------------------------------------"
echo ""

zip $( basename ${GPDB_INSTALLER_FILE} ) -u $( basename ${GPDB_INSTALLER_FILE} .zip ).bin
mv $( basename ${GPDB_INSTALLER_FILE} ) ..

openssl dgst -sha256 ../$( basename ${GPDB_INSTALLER_FILE} ) > ../$( basename ${GPDB_INSTALLER_FILE} ).sha256

echo ""
echo "----------------------------------------------------------------------"
echo "Done baking:"
echo "  $( ls -l ../$( basename ${GPDB_INSTALLER_FILE} )) "
echo "  $( ls -l ../$( basename ${GPDB_INSTALLER_FILE} )).sha256 "
echo "----------------------------------------------------------------------"

## ----------------------------------------------------------------------
## Retrieve and Extract Clients installer
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "Retrieve installer: $( basename ${CLIENTS_INSTALLER_FILE} )"
echo "----------------------------------------------------------------------"
echo ""

rm -f $( basename ${CLIENTS_INSTALLER_FILE} ) $( basename ${CLIENTS_INSTALLER_FILE} .zip ).bin

cp ${CLIENTS_INSTALLER_FILE} .
CLIENTS_BIN=$( basename ${CLIENTS_INSTALLER_FILE} .zip ).bin
unzip $( basename ${CLIENTS_INSTALLER_FILE} ) ${CLIENTS_BIN}
cp $( basename ${CLIENTS_INSTALLER_FILE} ) $( basename ${CLIENTS_INSTALLER_FILE} ).orig

## Retrieve installer shell script header
SKIP=$(awk '/^__END_HEADER__/ {print NR + 1; exit 0; }'  ${CLIENTS_BIN})
head -$( expr ${SKIP} - 1 ) ${CLIENTS_BIN} > header-clients.txt

## Extract installer payload (compressed tarball)
tail -n +${SKIP} ${CLIENTS_BIN} | tar zxf - -C ${CLIENTS_INSTALLDIR}

## Save original installer
mv ${CLIENTS_BIN} ${CLIENTS_BIN}.orig

## ----------------------------------------------------------------------
## Retrieve and Extract Connectivity installer
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "Retrieve installer: $( basename ${CONN_INSTALLER_FILE} )"
echo "----------------------------------------------------------------------"
echo ""

rm -f $( basename ${CONN_INSTALLER_FILE} ) $( basename ${CONN_INSTALLER_FILE} .zip ).bin

cp ${CONN_INSTALLER_FILE} .
CONN_BIN=$( basename ${CONN_INSTALLER_FILE} .zip ).bin
unzip $( basename ${CONN_INSTALLER_FILE} ) ${CONN_BIN}
cp $( basename ${CONN_INSTALLER_FILE} ) $( basename ${CONN_INSTALLER_FILE} ).orig

## Retrieve installer shell script header
SKIP=$(awk '/^__END_HEADER__/ {print NR + 1; exit 0; }'  ${CONN_BIN})
head -$( expr ${SKIP} - 1 ) ${CONN_BIN} > header-conn.txt

## Extract installer payload (compressed tarball)
tail -n +${SKIP} ${CONN_BIN} | tar zxf - -C ${CLIENTS_INSTALLDIR}

## Save original installer
mv ${CONN_BIN} ${CONN_BIN}.orig

## ----------------------------------------------------------------------
## Retrieve and Extract Loaders installer
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "Retrieve installer: $( basename ${LOADERS_INSTALLER_FILE} )"
echo "----------------------------------------------------------------------"
echo ""

rm -f $( basename ${LOADERS_INSTALLER_FILE} ) $( basename ${LOADERS_INSTALLER_FILE} .zip ).bin

cp ${LOADERS_INSTALLER_FILE} .
LOADERS_BIN=$( basename ${LOADERS_INSTALLER_FILE} .zip ).bin
unzip $( basename ${LOADERS_INSTALLER_FILE} ) ${LOADERS_BIN}
cp $( basename ${LOADERS_INSTALLER_FILE} ) $( basename ${LOADERS_INSTALLER_FILE} ).orig

## Retrieve installer shell script header
SKIP=$(awk '/^__END_HEADER__/ {print NR + 1; exit 0; }'  ${LOADERS_BIN})
head -$( expr ${SKIP} - 1 ) ${LOADERS_BIN} > header-loaders.txt

## Extract installer payload (compressed tarball)
tail -n +${SKIP} ${LOADERS_BIN} | tar zxf - -C ${CLIENTS_INSTALLDIR}

## Save original installer
mv ${LOADERS_BIN} ${LOADERS_BIN}.orig

## ----------------------------------------------------------------------
## Process JDBC Driver
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "JDBC Driver extraction: $( basename ${JDBC_DRIVER_FILE} )"
echo "----------------------------------------------------------------------"
echo ""

cp ${JDBC_DRIVER_FILE} .

unzip $( basename ${JDBC_DRIVER_FILE} )

mkdir -p ${CLIENTS_INSTALLDIR}/drivers/jdbc/$( basename ${JDBC_DRIVER_FILE} .zip )
mv greenplum.jar ${CLIENTS_INSTALLDIR}/drivers/jdbc/$( basename ${JDBC_DRIVER_FILE} .zip )

## ----------------------------------------------------------------------
## Process gpsupport
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "GPSupport retrieval: $( basename ${GPSUPPORT_FILE} )"
echo "----------------------------------------------------------------------"

cp ${GPSUPPORT_FILE} ${CLIENTS_INSTALLDIR}/bin/gpsupport.gz
gunzip ${CLIENTS_INSTALLDIR}/bin/gpsupport.gz
chmod a+x ${CLIENTS_INSTALLDIR}/bin/gpsupport

## ----------------------------------------------------------------------
## Process gpcheckmirrorseg.pl
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "QAUtils processing: $( basename ${QAUTILS_FILE} )"
echo "----------------------------------------------------------------------"

pushd ${CLIENTS_INSTALLDIR} > /dev/null
tar zxf ../$( basename ${QAUTILS_FILE} ) bin/gpcheckmirrorseg.pl
popd > /dev/null

## ----------------------------------------------------------------------
## Assemble CONN installer
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "Create updated installer payload (compressed tarball)"
echo "----------------------------------------------------------------------"

pushd ${CLIENTS_INSTALLDIR} > /dev/null
tar zcf ../$( basename ${CLIENTS_INSTALLER_FILE} .zip ).tgz *
popd > /dev/null

echo ""
echo "----------------------------------------------------------------------"
echo "Create updated installer bin file"
echo "----------------------------------------------------------------------"

rm -f /tmp/header-clients-*
sed -e "s/%RELEASE%/${RELEASE}/g" $SCRIPT_DIR/header-clients-template.txt > /tmp/header-clients-$$.txt
cat /tmp/header-clients-$$.txt $( basename ${CLIENTS_INSTALLER_FILE} .zip ).tgz > $( basename ${CLIENTS_INSTALLER_FILE} .zip ).bin
chmod a+x $( basename ${CLIENTS_INSTALLER_FILE} .zip ).bin

echo ""
echo "----------------------------------------------------------------------"
echo "Update original installer zip file with new installer"
echo "----------------------------------------------------------------------"
echo ""

zip $( basename ${CLIENTS_INSTALLER_FILE} ) -u $( basename ${CLIENTS_INSTALLER_FILE} .zip ).bin
mv $( basename ${CLIENTS_INSTALLER_FILE} ) ..
popd

openssl dgst -sha256 $( basename ${CLIENTS_INSTALLER_FILE} ) > $( basename ${CLIENTS_INSTALLER_FILE} ).sha256

echo ""
echo "----------------------------------------------------------------------"
echo "  $( ls -l $( basename ${CLIENTS_INSTALLER_FILE} )) "
echo "  $( ls -l $( basename ${CLIENTS_INSTALLER_FILE} )).sha256 "
echo "----------------------------------------------------------------------"

echo ""
echo "---------------------------------------------------------------------"
echo " Copy the generated artifacts to target output directory"
echo "---------------------------------------------------------------------"
echo ""

mkdir -p $BASE_DIR/ms_installer_rhel5_gpdb_rc $BASE_DIR/ms_installer_rhel5_gpdb_bundled_clients
cp greenplum-db-${RELEASE}-rhel5-x86_64.zip $BASE_DIR/ms_installer_rhel5_gpdb_rc/
cp greenplum-db-${RELEASE}-rhel5-x86_64.zip.sha256 $BASE_DIR/ms_installer_rhel5_gpdb_rc/
cp greenplum-clients-${RELEASE}-build-1-rhel5-x86_64.zip $BASE_DIR/ms_installer_rhel5_gpdb_bundled_clients/
cp greenplum-clients-${RELEASE}-build-1-rhel5-x86_64.zip.sha256 $BASE_DIR/ms_installer_rhel5_gpdb_bundled_clients/

echo ""
echo "---------------------------------------------------------------------"
echo " Completed "
echo "---------------------------------------------------------------------"
echo ""
