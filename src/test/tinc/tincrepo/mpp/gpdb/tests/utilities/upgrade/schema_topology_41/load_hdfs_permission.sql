/* Note that roles are defined at the system-level and are valid
 * for all databases in your Greenplum Database system. */
\echo '-- start_ignore'
DROP ROLE IF EXISTS _hadoop_perm_test_role;
DROP ROLE IF EXISTS _hadoop_perm_test_role2;
\echo '-- end_ignore'

/* Now create a new role. Initially this role should NOT
 * be allowed to create an external hdfs table. */

CREATE ROLE _hadoop_perm_test_role
WITH CREATEEXTTABLE
LOGIN;

CREATE ROLE _hadoop_perm_test_role2
WITH CREATEEXTTABLE
LOGIN;

ALTER ROLE _hadoop_perm_test_role
WITH
CREATEEXTTABLE(type='writable', protocol='gphdfs');

ALTER ROLE _hadoop_perm_test_role2
WITH
CREATEEXTTABLE(type='readable', protocol='gphdfs')
CREATEEXTTABLE(type='writable', protocol='gphdfs');

