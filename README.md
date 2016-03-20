# Greenplum overview

Greeplum is an MPP (Massively Parallel Processing) database engine, based
on PostgreSQL.

A Greenplum cluster consists of a "master" server, and multiple "segment"
servers. All user data resides in the segments, the master contains only
metadata. The master server, and all the segments, share the same schema.

Users always connect to the master server, which divides up the query into
fragments that are executed in the segments, sends the fragments to the
segments, and collects the results.

# Compiling on OSX

All the following steps are automated by scripts at https://github.com/greenplum-db/ci-infrastructure/tree/master/scripts. If you want to do it **manually**, please follow instructions below.

## Dependencies

* Java 1.6
* gcc 4.4.2 for OSX 106, assume installed at `/opt` with `/opt/gcc_env-osx106.sh` available
* All other dependencies are tracked by `./gpAux/releng/make/dependencies/ivy.xml` and will be retrieved automatically during build

## Environment

```
ulimit -n 65535;
export GPROOT=`pwd`/gpAux;
export JAVA_HOME=`/usr/libexec/java_home -v 1.6`;
source /opt/gcc_env-osx106.sh;
export MACOSX_DEPLOYMENT_TARGET=10.9;
```

## Build

```
cd gpAux/
# build optimized 32bit
make dist enable_gphdfs=yes ARCH_BIT=GPOS_32BIT CFLAGS="-Wno-deprecated";
```

## Compatibility Fix

Find `libz.1.dylib` under `greenplum-db-devel/` and remove it.

# Code layout

The directory layout of the repository follows the same general layout as
upstream PostgreSQL. There are changes compared to PostgreSQL throughout the
codebase, but a few larger additions worth noting:

`gpAux/`
	Contains Greenplum-specific extensions such as gpfdist and gpmapreduce.
	Some extension directories are submodules due to GPL license conflicts.

`gpMgmt/`
	Contains Greenplum-specific command-line tools for managing the
	cluster. Scripts like gpinit, gpstart, gpstop live here. They are
	mostly written in Python.

`doc/`
	In PostgreSQL, the user manual lives here. In Greenplum, the user
	manual is distributed separately (see http://gpdb.docs.pivotal.io), and
	only the reference pages used to build man pages are here.

`src/backend/cdb/`
	Contains larger Greenplum-specific backend modules. For example,
	communication between segments, turning plans into parallelizable
	plans, mirroring, distributed transaction and snapshot management,
	etc. "cdb" stands for "Cluster Database" - it was a workname used in
	the early days. That name is no longer used, but the "cdb" prefix
	remains.

`src/backend/gpopt`
	Contains the so-called "translator" library, for using the ORCA
	optimizer with Greenplum. The translator library is written in C++
	code, and contains glue code for translating plans and queries between
	the DXL format used by ORCA, and the PostgreSQL internal
	representation. This goes unused, unless building with --enable-orca.

`src/backend/gp_libpq_fe`
	A slightly modified copy of libpq. The master node uses this to
	connect to segments, and to send fragments of a query plan to segments
	for execution. It is linked directly into the backend, it is not a
	shared library like libpq.

`src/backend/fts`
	FTS is a process that runs in the master node, and periodically polls
	the segments to maintain the status of each segment.


# Regression tests

```
make installcheck-good  ## default regression tests
make installcheck-bugbuster  ## optional extra/heavier regression tests
## You can add TT=<test name> variable to the make command to run a single test
```

The PostgreSQL `check` target does not work. Setting up a Greenplum cluster
is more complicated than a single-node PostgreSQL installation, and no-one's
done the work to have `make check` create a cluster. Create a cluster
manually or use `gpAux/gpdemo/`, and run `make installcheck-good` against
that. Patches are welcome!

The PostgreSQL `installcheck` target does not work either, because some
tests are known to fail with Greenplum. The `installcheck-good` schedule
excludes those tests.

Example regression test run:
```
## Go to $GPHOME (configure --prefix install location)
source greenplum_path.sh
cd gpAux/gpdemo/
make cluster

## After make cluster, export PGPORT and MASTER_DATA_DIRECTORY
source gpdemo-env.sh
make installcheck-good
```

# Glossary

**QD** Query Dispatcher. A synonym for the master server.

**QE** Query Executor. A synonym for a segment server.


# Documentation

For Greenplum Database documentation, please check online docs:
http://gpdb.docs.pivotal.io
