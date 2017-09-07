#!/bin/bash

GPDB_INSTALLDIR=greenplum-db

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

mkdir greenplum-db
tar -xzf patched_bin_gpdb_ms/bin_gpdb.tar.gz -C ${GPDB_INSTALLDIR}
tar -xzf qautils_rhel5_tarball/QAUtils-rhel5-x86_64.tar.gz -C ${GPDB_INSTALLDIR}

extract_std_gppkg plperl_rhel6_gppkg/plperl-*-rhel6-x86_64.gppkg

echo ""
echo "----------------------------------------------------------------------"
echo "Create testable installer payload (compressed tarball)"
echo "----------------------------------------------------------------------"

pushd ${GPDB_INSTALLDIR} > /dev/null
  tar zcf ../bin_gpdb.tar.gz *
  # Copy updated tar to concourse output folder to pass to testing steps
popd > /dev/null

mv bin_gpdb.tar.gz patched_testable_bin_gpdb_ms/

echo ""
echo "---------------------------------------------------------------------"
echo " Completed "
echo "---------------------------------------------------------------------"
echo ""
