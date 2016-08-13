#!/bin/bash

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

    rm -f ${GPPKG}

    wget --no-check-certificate ${GPPKG_URL}
    if [ $? != 0 ]; then
        echo "FATAL: wget retrieval failed."
        exit 1
    fi

    tar tvf ${GPPKG} *.rpm | grep deps > /dev/null
    if [ $? = 0 ]; then
        DEPS=true
    fi

    BASE_RPM=$( tar tvf ${GPPKG} *.rpm | grep -v deps | awk '{print $6}' )

    tar xf ${GPPKG} ${BASE_RPM}
    if [ $? != 0 ]; then
        echo "FATAL: tar extraction failed."
        exit 1
    fi

    rm -rf deps temp $( basename ${BASE_RPM} .rpm )

    rpm2cpio ${BASE_RPM} | cpio -idm

    rm -f ${BASE_RPM}

    if [ ${DEPS} = "true" ]; then
        RPM=$( tar tvf ${GPPKG} *.rpm | grep -e "deps/.*.rpm" | awk '{print $6}' )
        tar xf ${GPPKG} ${RPM}
        rpm2cpio ${RPM} | cpio -idm

    fi

    mv temp $( basename ${BASE_RPM} .rpm )
    rm -rf deps

    rsync -au $( basename ${BASE_RPM} .rpm )/* ${GPDB_INSTALLDIR}
}

## ======================================================================

RELEASE=4.3.8.2MS26

GPDB_INSTALLER_URL=${GPDB_INSTALLER_URL:=http://gpdb:gpreleng@build-prod.dh.greenplum.com/internal-builds/greenplum-db/rc/${RELEASE}-build-1/archive/greenplum-db-${RELEASE}-build-1-RHEL5-x86_64.zip}
CONN_INSTALLER_URL=${CONN_INSTALLER_URL:=http://gpdb:gpreleng@build-prod.dh.greenplum.com/internal-builds/greenplum-db/rc/${RELEASE}-build-1/archive/greenplum-connectivity-${RELEASE}-build-1-RHEL5-x86_64.zip}
CLIENTS_INSTALLER_URL=${CLIENTS_INSTALLER_URL:=http://gpdb:gpreleng@build-prod.dh.greenplum.com/internal-builds/greenplum-db/rc/${RELEASE}-build-1/archive/greenplum-clients-${RELEASE}-build-1-RHEL5-x86_64.zip}
LOADERS_INSTALLER_URL=${LOADERS_INSTALLER_URL:=http://gpdb:gpreleng@build-prod.dh.greenplum.com/internal-builds/greenplum-db/rc/${RELEASE}-build-1/archive/greenplum-loaders-${RELEASE}-build-1-RHEL5-x86_64.zip}
QAUTILS_URL=${QAUTILS_URL:=http://gpdb:gpreleng@build-prod.dh.greenplum.com/internal-builds/greenplum-db/rc/${RELEASE}-build-1/qautils/QAUtils-RHEL5-x86_64.tar.gz}

PGCRYPTO_GPPKG_URL=${PGCRYPTO_GPPKG_URL:=http://build-prod.dh.greenplum.com/releases/greenplum-db/gppkg/pgcrypto/pgcrypto-ossv1.1_pv1.2_gpdb4.3orca-rhel5-x86_64.gppkg}

PLR_GPPKG_URL=${PLR_GPPKG_URL:=http://build-prod.dh.greenplum.com/releases/greenplum-db/gppkg/plr/plr-ossv8.3.0.15_pv2.1_gpdb4.3orca-rhel5-x86_64.gppkg}
##PLJAVA_GPPKG_URL=${PLJAVA_GPPKG_URL:=http://build-prod.dh.greenplum.com/releases/greenplum-db/gppkg/pljava/pljava-ossv1.4.0_pv1.3_gpdb4.3orca-rhel5-x86_64.gppkg}
PLJAVA_GPPKG_URL=${PLJAVA_GPPKG_URL:=http://gpdb:gpreleng@build-prod.dh.greenplum.com/internal-builds/greenplum-db/rc/4.3.7.0-build-1//pljava-ossv1.4.0_pv1.3_gpdb4.3orca-rhel5-x86_64.gppkg}

MADLIB_GPPKG_URL=${MADLIB_GPPKG_URL:=http://build-prod.dh.greenplum.com/releases/greenplum-db/gppkg/madlib/madlib-ossv1.7.1_pv1.9.3_gpdb4.3orca-rhel5-x86_64.gppkg}
JDBC_DRIVER_URL=${JDBC_DRIVER_URL:=http://build-prod.dh.greenplum.com/releases/greenplum-db/datadirect/greenplum_jdbc_5.1.1.zip}
GPSUPPORT_URL=${GPSUPPORT_URL:=http://build-prod.dh.greenplum.com/releases/greenplum-db/gpsupport/1.2.0.0/gpsupport-1.2.0.0.gz}

cat <<-EOF
======================================================================
TIMESTAMP ..... : $(date)
----------------------------------------------------------------------

  RELEASE .................. : ${RELEASE}

  GPDB_INSTALLER_URL ....... : ${GPDB_INSTALLER_URL}
  CONN_INSTALLER_URL ....... : ${CONN_INSTALLER_URL}
  CLIENTS_INSTALLER_URL .... : ${CLIENTS_INSTALLER_URL}
  LOADERS_INSTALLER_URL .... : ${LOADERS_INSTALLER_URL}
  QAUTILS_URL .............. : ${QAUTILS_URL}
  PGCRYPTO_GPPKG_URL ....... : ${PGCRYPTO_GPPKG_URL}
  PLR_GPPKG_URL ............ : ${PLR_GPPKG_URL}
  PLJAVA_GPPKG_URL ......... : ${PLJAVA_GPPKG_URL}
  MADLIB_GPPKG_URL ......... : ${MADLIB_GPPKG_URL}
  JDBC_DRIVER_URL .......... : ${JDBC_DRIVER_URL}
  GPSUPPORT_URL ............ : ${GPSUPPORT_URL}

======================================================================
EOF

rm -rf build
mkdir build
cd build

mkdir ${GPDB_INSTALLDIR} ${CLIENTS_INSTALLDIR}

## ----------------------------------------------------------------------
## Retrieve and Extract GPDB installer
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "Retrieve installer: $( basename ${GPDB_INSTALLER_URL} )"
echo "----------------------------------------------------------------------"
echo ""

rm -f $( basename ${GPDB_INSTALLER_URL} ) $( basename ${GPDB_INSTALLER_URL} .zip ).bin

wget -nv ${GPDB_INSTALLER_URL}
GPDB_BIN=$( basename ${GPDB_INSTALLER_URL} .zip ).bin
unzip $( basename ${GPDB_INSTALLER_URL} ) ${GPDB_BIN}
cp $( basename ${GPDB_INSTALLER_URL} ) $( basename ${GPDB_INSTALLER_URL} ).orig

## Retrieve installer shell script header
SKIP=$(awk '/^__END_HEADER__/ {print NR + 1; exit 0; }'  ${GPDB_BIN})
head -$( expr ${SKIP} - 1 ) ${GPDB_BIN} > header-gpdb.txt

## Extract installer payload (compressed tarball)
tail -n +${SKIP} ${GPDB_BIN} | tar zxf - -C ${GPDB_INSTALLDIR}

## Save original installer
mv ${GPDB_BIN} ${GPDB_BIN}.orig

## ----------------------------------------------------------------------
## Process GPPKGS
## ----------------------------------------------------------------------

extract_std_gppkg ${PLJAVA_GPPKG_URL}

extract_std_gppkg ${PGCRYPTO_GPPKG_URL}

extract_std_gppkg ${PLR_GPPKG_URL}

echo ""
echo "Update greenplum_path.sh"

echo '' >> ${GPDB_INSTALLDIR}/greenplum_path.sh
echo 'export R_HOME=$GPHOME/ext/R-3.1.0/lib64/R' >> ${GPDB_INSTALLDIR}/greenplum_path.sh

JAVA_VER1=$(basename ${GPDB_INSTALLDIR}/ext/jre*)
JAVA_VER2=$(basename ${GPDB_INSTALLDIR}/ext/jre*/jre*)

echo 'export JAVA_HOME=$GPHOME/ext/'"${JAVA_VER1}/${JAVA_VER2}" >> ${GPDB_INSTALLDIR}/greenplum_path.sh
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ${GPDB_INSTALLDIR}/greenplum_path.sh
echo 'export LD_LIBRARY_PATH=$GPHOME/ext/R-3.1.0/lib64/R/lib:$JAVA_HOME/lib/amd64/server:$LD_LIBRARY_PATH' >> ${GPDB_INSTALLDIR}/greenplum_path.sh

## ----------------------------------------------------------------------
## Process Alpine
## ----------------------------------------------------------------------

echo ""
echo "Include Alpine"

rsync -auv --exclude=src ../alpine ${GPDB_INSTALLDIR}/ext
cp -v ${GPDB_INSTALLDIR}/ext/alpine/sharedLib/4.3.5/alpine_miner.centos_64bit.so ${GPDB_INSTALLDIR}/lib/postgresql/alpine_miner.so

chmod 755 ${GPDB_INSTALLDIR}/lib/postgresql/alpine_miner.so ${GPDB_INSTALLDIR}/ext/alpine/sharedLib/4.3.5/alpine_miner.centos_64bit.so

pushd ${GPDB_INSTALLDIR}/ext/alpine/sharedLib/4.3.5
ln -s alpine_miner.centos_64bit.so alpine_miner.so
popd

## ----------------------------------------------------------------------
## Process MADlib
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "MADlib extraction: $( basename ${MADLIB_GPPKG_URL} )"
echo "----------------------------------------------------------------------"
echo ""

mkdir madlib_temp
pushd madlib_temp > /dev/null

wget -nv ${MADLIB_GPPKG_URL}
tar zxf $( basename ${MADLIB_GPPKG_URL} )

rpm2cpio *.rpm | cpio -idm

pushd usr/local/madlib > /dev/null
ln -s Versions/1.7.1 Current
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
echo "GPSupport retrieval: $( basename ${GPSUPPORT_URL} )"
echo "----------------------------------------------------------------------"

wget -nv --user=gpdb --password=gprelease ${GPSUPPORT_URL} -O ${GPDB_INSTALLDIR}/bin/gpsupport.gz
gunzip ${GPDB_INSTALLDIR}/bin/gpsupport.gz

chmod a+x ${GPDB_INSTALLDIR}/bin/gpsupport

## ----------------------------------------------------------------------
## Process gpcheckmirrorseg.pl
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "QAUtils retrieval: $( basename ${QAUTILS_URL} )"
echo "----------------------------------------------------------------------"

wget -nv ${QAUTILS_URL}
pushd ${GPDB_INSTALLDIR} > /dev/null
tar zxf ../$( basename ${QAUTILS_URL} ) bin/gpcheckmirrorseg.pl
popd > /dev/null

## ----------------------------------------------------------------------
## Retrieve and Extract CONN installer
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "Retrieve installer: $( basename ${CONN_INSTALLER_URL} )"
echo "----------------------------------------------------------------------"
echo ""

rm -f $( basename ${CONN_INSTALLER_URL} ) $( basename ${CONN_INSTALLER_URL} .zip ).bin

wget -nv ${CONN_INSTALLER_URL}
CONN_BIN=$( basename ${CONN_INSTALLER_URL} .zip ).bin
unzip $( basename ${CONN_INSTALLER_URL} ) ${CONN_BIN}
cp $( basename ${CONN_INSTALLER_URL} ) $( basename ${CONN_INSTALLER_URL} ).orig

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
echo "JDBC Driver extraction: $( basename ${JDBC_DRIVER_URL} )"
echo "----------------------------------------------------------------------"
echo ""

wget -nv ${JDBC_DRIVER_URL}
if [ $? != 0 ]; then
    echo "FATAL: wget retrieval failed."
    exit 1
fi

unzip $( basename ${JDBC_DRIVER_URL} )
if [ $? != 0 ]; then
    echo "FATAL: unzip failed."
    exit 1
fi

mkdir -p ${GPDB_INSTALLDIR}/drivers/jdbc/$( basename ${JDBC_DRIVER_URL} .zip )
mv greenplum.jar ${GPDB_INSTALLDIR}/drivers/jdbc/$( basename ${JDBC_DRIVER_URL} .zip )

## ----------------------------------------------------------------------
## If any, apply patches
## ----------------------------------------------------------------------

pushd ${GPDB_INSTALLDIR} > /dev/null

echo ""
echo "----------------------------------------------------------------------"
echo "Applying patche(s)"
echo "----------------------------------------------------------------------"
echo ""

for patch in ../../patches/GPDB-patch*; do
    patch --backup -p1 < ${patch}
    if [ $? != 0 ]; then
        echo "FATAL: patch failed to be applied (${patch})"
        exit 1
    fi
done

popd > /dev/null

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
    for i in `cat ../scripts/checksums.$i | awk '{print $2}'`; do
		if [ -f ${GPDB_INSTALLDIR}/$i ]; then
        	rm -fv ${GPDB_INSTALLDIR}/$i
		fi
    done
done

rm -rf krb5-rhel55_x86_64-1.13.targ
wget -nv --no-check-certificate https://repo.eng.pivotal.io/artifactory/gpdb-ext-release-local/mit/krb5/1.13/targzs/krb5-rhel62_x86_64-1.13.targz
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
tar zcf ../$( basename ${GPDB_INSTALLER_URL} .zip ).tgz *
popd > /dev/null

echo ""
echo "----------------------------------------------------------------------"
echo "Create updated installer bin file"
echo "----------------------------------------------------------------------"

rm -f /tmp/header-gpdb-*
sed -e "s/%RELEASE%/${RELEASE}/g" ../scripts/header-gpdb-template.txt > /tmp/header-gpdb-$$.txt
cat /tmp/header-gpdb-$$.txt $( basename ${GPDB_INSTALLER_URL} .zip ).tgz > $( basename ${GPDB_INSTALLER_URL} .zip ).bin
chmod a+x $( basename ${GPDB_INSTALLER_URL} .zip ).bin

echo ""
echo "----------------------------------------------------------------------"
echo "Update original installer zip file with new installer"
echo "----------------------------------------------------------------------"
echo ""

zip $( basename ${GPDB_INSTALLER_URL} ) -u $( basename ${GPDB_INSTALLER_URL} .zip ).bin
mv $( basename ${GPDB_INSTALLER_URL} ) ..

openssl dgst -md5 ../$( basename ${GPDB_INSTALLER_URL} ) > ../$( basename ${GPDB_INSTALLER_URL} ).md5

echo ""
echo "----------------------------------------------------------------------"
echo "Done baking:"
echo "  $( ls -l ../$( basename ${GPDB_INSTALLER_URL} )) "
echo "  $( ls -l ../$( basename ${GPDB_INSTALLER_URL} )).md5 "
echo "----------------------------------------------------------------------"

echo ""
echo "----------------------------------------------------------------------"
echo "Copy to build-prod.dh.greenplum.com"
echo "----------------------------------------------------------------------"
echo ""

echo scp ../$( basename ${GPDB_INSTALLER_URL} ) build@build-prod.dh.greenplum.com:/var/www/html/internal-builds/greenplum-db/rc/${RELEASE}-build-1/
scp ../$( basename ${GPDB_INSTALLER_URL} ) build@build-prod.dh.greenplum.com:/var/www/html/internal-builds/greenplum-db/rc/${RELEASE}-build-1/
echo scp ../$( basename ${GPDB_INSTALLER_URL} ).md5 build@build-prod.dh.greenplum.com:/var/www/html/internal-builds/greenplum-db/rc/${RELEASE}-build-1/
scp ../$( basename ${GPDB_INSTALLER_URL} ).md5 build@build-prod.dh.greenplum.com:/var/www/html/internal-builds/greenplum-db/rc/${RELEASE}-build-1/

## ----------------------------------------------------------------------
## Retrieve and Extract Clients installer
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "Retrieve installer: $( basename ${CLIENTS_INSTALLER_URL} )"
echo "----------------------------------------------------------------------"
echo ""

rm -f $( basename ${CLIENTS_INSTALLER_URL} ) $( basename ${CLIENTS_INSTALLER_URL} .zip ).bin

wget -nv ${CLIENTS_INSTALLER_URL}
CLIENTS_BIN=$( basename ${CLIENTS_INSTALLER_URL} .zip ).bin
unzip $( basename ${CLIENTS_INSTALLER_URL} ) ${CLIENTS_BIN}
cp $( basename ${CLIENTS_INSTALLER_URL} ) $( basename ${CLIENTS_INSTALLER_URL} ).orig

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
echo "Retrieve installer: $( basename ${CONN_INSTALLER_URL} )"
echo "----------------------------------------------------------------------"
echo ""

rm -f $( basename ${CONN_INSTALLER_URL} ) $( basename ${CONN_INSTALLER_URL} .zip ).bin

wget -nv ${CONN_INSTALLER_URL}
CONN_BIN=$( basename ${CONN_INSTALLER_URL} .zip ).bin
unzip $( basename ${CONN_INSTALLER_URL} ) ${CONN_BIN}
cp $( basename ${CONN_INSTALLER_URL} ) $( basename ${CONN_INSTALLER_URL} ).orig

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
echo "Retrieve installer: $( basename ${LOADERS_INSTALLER_URL} )"
echo "----------------------------------------------------------------------"
echo ""

rm -f $( basename ${LOADERS_INSTALLER_URL} ) $( basename ${LOADERS_INSTALLER_URL} .zip ).bin

wget -nv ${LOADERS_INSTALLER_URL}
LOADERS_BIN=$( basename ${LOADERS_INSTALLER_URL} .zip ).bin
unzip $( basename ${LOADERS_INSTALLER_URL} ) ${LOADERS_BIN}
cp $( basename ${LOADERS_INSTALLER_URL} ) $( basename ${LOADERS_INSTALLER_URL} ).orig

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
echo "JDBC Driver extraction: $( basename ${JDBC_DRIVER_URL} )"
echo "----------------------------------------------------------------------"
echo ""

wget -nv ${JDBC_DRIVER_URL}

unzip $( basename ${JDBC_DRIVER_URL} )

mkdir -p ${CLIENTS_INSTALLDIR}/drivers/jdbc/$( basename ${JDBC_DRIVER_URL} .zip )
mv greenplum.jar ${CLIENTS_INSTALLDIR}/drivers/jdbc/$( basename ${JDBC_DRIVER_URL} .zip )

## ----------------------------------------------------------------------
## Process gpsupport
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "GPSupport retrieval: $( basename ${GPSUPPORT_URL} )"
echo "----------------------------------------------------------------------"

wget -nv ${GPSUPPORT_URL} -O ${CLIENTS_INSTALLDIR}/bin/gpsupport
chmod a+x ${CLIENTS_INSTALLDIR}/bin/gpsupport

## ----------------------------------------------------------------------
## Process gpcheckmirrorseg.pl
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "QAUtils processing: $( basename ${QAUTILS_URL} )"
echo "----------------------------------------------------------------------"

pushd ${CLIENTS_INSTALLDIR} > /dev/null
tar zxf ../$( basename ${QAUTILS_URL} ) bin/gpcheckmirrorseg.pl
popd > /dev/null

## ----------------------------------------------------------------------
## If any, apply patches
## ----------------------------------------------------------------------

pushd ${CLIENTS_INSTALLDIR} > /dev/null

echo ""
echo "----------------------------------------------------------------------"
echo "Applying patche(s)"
echo "----------------------------------------------------------------------"
echo ""

for patch in ../../patches/CLIENTS-patch*; do
    patch --backup -p1 < ${patch}
    if [ $? != 0 ]; then
        echo "FATAL: patch failed to be applied (${patch})"
        exit 1
    fi
done

popd > /dev/null

## ----------------------------------------------------------------------
## Assemble CONN installer
## ----------------------------------------------------------------------

echo ""
echo "----------------------------------------------------------------------"
echo "Create updated installer payload (compressed tarball)"
echo "----------------------------------------------------------------------"

pushd ${CLIENTS_INSTALLDIR} > /dev/null
tar zcf ../$( basename ${CLIENTS_INSTALLER_URL} .zip ).tgz *
popd > /dev/null

echo ""
echo "----------------------------------------------------------------------"
echo "Create updated installer bin file"
echo "----------------------------------------------------------------------"

rm -f /tmp/header-clients-*
sed -e "s/%RELEASE%/${RELEASE}/g" ../scripts/header-clients-template.txt > /tmp/header-clients-$$.txt
cat /tmp/header-clients-$$.txt $( basename ${CLIENTS_INSTALLER_URL} .zip ).tgz > $( basename ${CLIENTS_INSTALLER_URL} .zip ).bin
chmod a+x $( basename ${CLIENTS_INSTALLER_URL} .zip ).bin

echo ""
echo "----------------------------------------------------------------------"
echo "Update original installer zip file with new installer"
echo "----------------------------------------------------------------------"
echo ""

zip $( basename ${CLIENTS_INSTALLER_URL} ) -u $( basename ${CLIENTS_INSTALLER_URL} .zip ).bin
mv $( basename ${CLIENTS_INSTALLER_URL} ) ..
cd ..

openssl dgst -md5 $( basename ${CLIENTS_INSTALLER_URL} ) > $( basename ${CLIENTS_INSTALLER_URL} ).md5

echo ""
echo "----------------------------------------------------------------------"
echo "  $( ls -l $( basename ${CLIENTS_INSTALLER_URL} )) "
echo "  $( ls -l $( basename ${CLIENTS_INSTALLER_URL} )).md5 "
echo "----------------------------------------------------------------------"

echo ""
echo "----------------------------------------------------------------------"
echo "Copy to build-prod.dh.greenplum.com"
echo "----------------------------------------------------------------------"
echo ""

echo scp $( basename ${CLIENTS_INSTALLER_URL} ) build@build-prod.dh.greenplum.com:/var/www/html/internal-builds/greenplum-db/rc/${RELEASE}-build-1/
scp $( basename ${CLIENTS_INSTALLER_URL} ) build@build-prod.dh.greenplum.com:/var/www/html/internal-builds/greenplum-db/rc/${RELEASE}-build-1/
echo scp $( basename ${CLIENTS_INSTALLER_URL} ).md5 build@build-prod.dh.greenplum.com:/var/www/html/internal-builds/greenplum-db/rc/${RELEASE}-build-1/
scp $( basename ${CLIENTS_INSTALLER_URL} ).md5 build@build-prod.dh.greenplum.com:/var/www/html/internal-builds/greenplum-db/rc/${RELEASE}-build-1/
