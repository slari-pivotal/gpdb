Stanley ![Morgan icon](http://dist.dh.greenplum.com/dist/GPDB/images/customers/morgan-stanley-logo.gif)

## Overview

**Scripts**, processes for creating Morgan Stanley specific installers.

Aside for updating the product's version string to include a sequential
incremental release, a GA source base is built following standard release
building procedures.  The packages below are then added into the payload,
environment file(s) (eg: greenplum_path.sh) are updated and files are patched
(possibly).

A customer specific branch is used to store the corresponding release version
scripts, patches and anything else necessary to generate a custom installer.

### Release Information

We traditionally kept the version number and md5 checksums for our release notes
and zip files here. The version number can now be found (and updated) in the
`getversion` script, and the md5 shasums are shipped directly from Concourse to
the S3 bucket where we retrieve the artifacts.

### Red Hat Enterprise Linux - Server Package updates
In addition to its normal contents, the following packages are included in the Greenplum Database (db) installer.  Installing in `standard` location (below) indicates the standard gppkg installation directory has not changed.

* **PGcrypto** - pgcrypto-ossv1.1_pv1.2_gpdb4.3orca-rhel5-x86_64.gppkg
	* installed in `standard` location
* **PL/R** - greenplum_path.sh is updated - plr-ossv8.3.0.15_pv2.1_gpdb4.3orca-rhel5-x86_64.gppkg
	* installed in `standard` location
* **PL/Java** - greenplum_path.sh is updated - pljava-ossv1.4.0_pv1.3_gpdb4.3orca-rhel5-x86_64.gppkg
	* installed in `standard` location
* **MADlib** - madlib-ossv1.9.1_pv1.9.5_gpdb4.3orca-rhel5-x86_64.gppkg
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

* The release files need to be copied to the standard ftp location.
* Windows packages are not included in this release.
