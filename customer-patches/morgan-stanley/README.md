Stanley ![Morgan icon](http://dist.dh.greenplum.com/dist/GPDB/images/customers/morgan-stanley-logo.gif)

## Overview

**Scripts**, processes for creating Morgan Stanley specific installers.

Aside for updating the products version string to include a sequential incremental release, a GA source base is built following standard release building procedures.  The packages below are then added into the payload, environment file(s) (eg: greenplum_path.sh) are updated and files are patched (possibly).

A customer specific branch is used to store the corresponding release version scripts, patches and anything else necessary to generate a custom installer.

### Release Information
* Version: GPDB 4.3.9.0MS27
* md5 info
	* Release Notes
		* GPDB_4390_README.pdf (md5: 240b47054d547ddb9ed0771b02eef6ab)

	* Red Hat Enterprise Linux
		* greenplum-db-4.3.9.0MS27-build-1-RHEL5-x86_64.zip (md5: 2750dd9644804470b85246f81f5dd8ce)
		* greenplum-clients-4.3.9.0MS27-build-1-RHEL5-x86_64.zip (md5: 2426ae6b501b0e7c739f698a4d8474ba)

### Red Hat Enterprise Linux - Server Package updates
In addition to it's normal contents, the following packages are included in the Greenplum Database (db) installer.  Installing in `standard` location (below) indicates the standard gppkg installation directory has not changed.

* **PGcrypto** - pgcrypto-ossv1.1_pv1.2_gpdb4.3orca-rhel5-x86_64.gppkg
	* installed in `standard` location
* **PL/R** - greenplum_path.sh is updated - plr-ossv8.3.0.15_pv2.1_gpdb4.3orca-rhel5-x86_64.gppkg
	* installed in `standard` location
* **PL/Java** - greenplum_path.sh is updated - pljava-ossv1.4.0_pv1.3_gpdb4.3orca-rhel5-x86_64.gppkg
	* installed in `standard` location
* **MADlib** - madlib-ossv1.9_pv1.9.5_gpdb4.3orca-rhel5-x86_64.gppkg
	* installed in `madlib` directory
* **gpsupport** - 1.2.0.0
	* single file installed in `bin/gpsupport`
* **gpcheckmirrorseg.pl**
	* single file installed in `bin/gpcheckmirrorseg.pl`
* **connectivity**
	* extract standard release connectivity package
* **Datadirect JDBC Driver** - greenplum_jdbc_5.1.1.zip
	* single file installed in `drivers/jdbc/greenplum_jdbc_5.1.1/greenplum.jar`
* **Kerberos 1.13 libraries**
	* installed in `standard` location
* **Alpine 5.4 "pre-release" UDFs built for GPDB 4.3.5.0**
	* installed in ext/alpine

### Red Hat Enterprise Linux - Clients Package updates
In addition to it's normal contents, the following package is included in the Greenplum connectivity installer.

* **clients**
	* extract standard release clients package
* **connectivity**
	* extract standard release connectivity package
	* includes postgresql-9.42-1208.jdbc41.jar,postgresql-9.4-1208.jdbc41.jar & postgresql-9.4-1208.jdbc4.jar
* **loaders**
	* extract standard release loaders package
* **Datadirect JDBC Driver** - greenplum_jdbc_5.1.1.zip
	* single file installed in `drivers/jdbc/greenplum_jdbc_5.1.1/greenplum.jar`
* **gpsupport** - 1.2.0.0
	* single file installed in `bin/gpsupport`
* **gpcheckmirrorseg.pl**
	* single file installed in `bin/gpcheckmirrorseg.pl`

### Additional notes
* For reference, the release notes are attached to this email.
* The release files have been copied to the standard ftp location.
* Windows packages are not included in this release.
