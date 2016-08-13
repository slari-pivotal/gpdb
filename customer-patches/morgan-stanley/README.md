Stanley ![Morgan icon](http://dist.dh.greenplum.com/dist/GPDB/images/customers/morgan-stanley-logo.gif)

## Overview

**Scripts**, processes for creating Morgan Stanley specific installers.

Aside for updating the products version string to include a sequential incremental release, a GA source base is built following standard release building procedures.  The packages below are then added into the payload, environment file(s) (eg: greenplum_path.sh) are updated and files are patched (possibly).

A customer specific branch is used to store the corresponding release version scripts, patches and anything else necessary to generate a custom installer.

### Release Information
* Version: GPDB 4.3.8.2MS26
* md5 info
	* Release Notes
		* GPDB_4382_README.pdf (md5: 8369d67bd782b2c70314809d4d0dc7d0)

	* Red Hat Enterprise Linux
		* greenplum-db-4.3.8.2MS26-build-1-RHEL5-x86_64.zip (md5: feb8be803d8d684cd6249e4be7425d21)
		* greenplum-clients-4.3.8.2MS26-build-1-RHEL5-x86_64.zip (md5: 151577a37dc31ba37c82ffb8264974b7)

	* Microsoft Windows
		* greenplum-clients-4.3.8.2MS26-build-1-WinXP-x86_32.msi (md5: 54fd8f58496812c6f4da8b789d299182)
		* greenplum-connectivity-4.3.8.2MS26-build-1-WinXP-x86_32.msi (md5: d0f30c3fd29b514cd2abace29e143f63)
		* greenplum-loaders-4.3.8.2MS26-build-1-WinXP-x86_32.msi (md5: bde348b59894a85d0c2e0bf31e258776)
		* psqlodbc_09_05_0210-x64.zip (md5: bf5c4a69dfa266341217dd8b80e41091)
		* psqlodbc_09_05_0210-x86.zip (md5: eec287c0018b14ae0ff4160c52659a2d)

### Red Hat Enterprise Linux - Server Package updates
In addition to it's normal contents, the following packages are included in the Greenplum Database (db) installer.  Installing in `standard` location (below) indicates the standard gppkg installation directory has not changed.

* **PGcrypto** - pgcrypto-ossv1.1_pv1.2_gpdb4.3orca-rhel5-x86_64.gppkg
	* installed in `standard` location
* **PL/R** - greenplum_path.sh is updated - plr-ossv8.3.0.15_pv2.1_gpdb4.3orca-rhel5-x86_64.gppkg
	* installed in `standard` location
* **PL/Java** - greenplum_path.sh is updated - pljava-ossv1.4.0_pv1.3_gpdb4.3orca-rhel5-x86_64.gppkg
	* installed in `standard` location
* **MADlib** - madlib-ossv1.7.1_pv1.9.3_gpdb4.3orca-rhel5-x86_64.gppkg
	* installed in `madlib` directory
* **gpsupport** - 1.2.0.0
	* single file installed in `bin/gpsupport`
* **gpcheckmirrorseg.pl**
	* single file installed in `bin/gpcheckmirrorseg.pl`
* **connectivity**
	* extract standard release connectivity package
* MS specific **patches** have been applied.  Original files are located in place with the .orig extension added.
	* bin/gpmigrator_mirror
	* lib/python/gppylib/operations/gpMigratorUtil.py
* **Datadirect JDBC Driver** - greenplum_jdbc_5.1.1.zip
	* single file installed in `drivers/jdbc/greenplum_jdbc_5.1.1/greenplum.jar`
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
* MS specific **patch** has been applied.  Original file is located in place with the .orig extension added.
	* lib/python/gppylib/operations/gpMigratorUtil.py

### Microsoft Windows
* **connectivity**
	* We are now providing the psqlodbc 09.05.0210 32 & 64bit driver.

### Additional notes
* For reference, the release notes are attached to this email.
* The release files have been copied to the standard ftp location.
