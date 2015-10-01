#!/usr/bin/env python

import os
import time

from datetime import datetime
from gppylib import gplog
from gppylib.db import dbconn
from gppylib.db.dbconn import execSQL, execSQLForSingleton
from gppylib.gpparseopts import OptParser, OptChecker
from gppylib.mainUtils import simple_main
from gppylib.mainUtils import addStandardLoggingAndHelpOptions

logger = gplog.get_default_logger()

TIMESTAMP = datetime.now().strftime("%Y%m%d%H%M%S")
ORPHAN_TABLES_SCHEMA = 'orphan_tables_schema'
ORPHAN_TABLES_FILE = 'orphan_tables_file_{time}'.format(time= TIMESTAMP)


class FixOrphanTables:
    def __init__(self, options, args):
        self.port = options.port or os.environ.get('$PGPORT', None)
        self.dbnames = options.dbnames 
        self.table_file = options.table_file
        self.conn = None

    def _connect_to_db(self, dbname):
        self.conn = dbconn.connect(dbconn.DbURL(dbname=dbname, port=self.port))

    def _close_connection(self):
        if self.conn:
            self.conn.close()
            self.conn = None

    def _get_all_databases(self):
        GET_DATABASE_QUERY = """ SELECT datname FROM pg_database WHERE datname <> 'template0';"""
        with dbconn.connect(dbconn.DbURL(dbname='postgres', port=self.port)) as conn:
            res = dbconn.execSQL(conn, GET_DATABASE_QUERY)
        return map(lambda x: str(x)[2:-2], res)

    def _generate_orphan_table_list(self):
        ORPHAN_TABLES_QUERY = """
-- distribute pg_class table from master, so that we can have relname to gather
CREATE TEMPORARY TABLE _tmp_master ON COMMIT DROP AS
SELECT gp_segment_id segid, relname, relnamespace FROM pg_class WHERE relkind = 'r';

SELECT distinct(relname)
    FROM
    (
        SELECT ideal.*,
        case when actual.segid is null then 'missing' else 'extra' end as exists,
        count(*) over (partition by relname, actual.segid is null) as subcount
        FROM (
            SELECT segid, relname 
            FROM(  SELECT distinct n.nspname || '.' || c.relname as relname FROM _tmp_master c, pg_namespace n WHERE c.relnamespace = n.oid
                   UNION 
                   SELECT distinct n.nspname || '.' || c.relname as relname FROM gp_dist_random('pg_class') c, pg_namespace n
                   WHERE c.relnamespace = n.oid AND c.relkind = 'r'
                ) all_pks,
                ( SELECT distinct content as segid from gp_segment_configuration) all_segs
            ) ideal
            LEFT OUTER JOIN
            ( SELECT c.segid, n.nspname || '.' || c.relname as relname FROM _tmp_master c, pg_namespace n WHERE c.relnamespace = n.oid
                UNION ALL
              SELECT c.gp_segment_id as segid, n.nspname || '.' || c.relname as relname FROM gp_dist_random('pg_class') c, pg_namespace n
              WHERE c.relnamespace = n.oid AND c.relkind = 'r'
            ) actual 
        USING (segid, relname)
   ) missing_extra
WHERE subcount <= (0+2)/2.0
AND missing_extra.segid = -1 AND missing_extra.exists = 'missing'
GROUP BY relname, exists;
        """
        res = dbconn.execSQL(self.conn, ORPHAN_TABLES_QUERY).fetchall()
        return map(lambda x: str(x)[2:-2], res)

    def _create_orphan_table_schema(self):
        CREATE_ORPHAN_TABLES_SCHEMA_QUERY = """
        CREATE SCHEMA {schema}
        """.format(schema=ORPHAN_TABLES_SCHEMA)

        dbconn.execSQL(self.conn, CREATE_ORPHAN_TABLES_SCHEMA_QUERY)
        self.conn.commit()

    def _create_drop_functions(self):
        CATDML_FUNCTION_QUERY = """
        -- Use this pl/pgsql function to execute DML on cat tab on all segs
        CREATE OR REPLACE FUNCTION {schema}.catDML(stmt text) RETURNS INT 
        AS $$
        DECLARE
        CONTENTID integer;
        BEGIN
        SELECT INTO contentid current_setting('gp_contentid');
        IF contentid = -1 THEN
            PERFORM {schema}.catDML(stmt) FROM gp_dist_random('gp_id');
        END IF; 
        IF contentid <> -1 THEN
            execute stmt;
        END IF; 
        return 1;
        END;
        $$ LANGUAGE 'plpgsql';
        """.format(schema=ORPHAN_TABLES_SCHEMA)

        DROP_ORPHAN_TABLES_FUNCTION_QUERY = """
        CREATE OR REPLACE FUNCTION {schema}.drop_orphan_table(tablename text) RETURNS INT 
        AS $$
        BEGIN
            SET allow_segment_DML=true;
            PERFORM {schema}.catDML('DROP TABLE IF EXISTS ' || tablename);
            return 1;
        END
        $$ LANGUAGE 'plpgsql';
        """.format(schema=ORPHAN_TABLES_SCHEMA)

        dbconn.execSQL(self.conn, CATDML_FUNCTION_QUERY)
        self.conn.commit()
        dbconn.execSQL(self.conn, DROP_ORPHAN_TABLES_FUNCTION_QUERY)
        self.conn.commit()

    def _remove_drop_functions(self):
        REMOVE_CATDML_FUNCTION = """ DROP FUNCTION {schema}.catDML(stmt text)""".format(schema=ORPHAN_TABLES_SCHEMA)
        REMOVE_DROP_ORPHAN_TABLE_FUNCTION = """ DROP FUNCTION {schema}.drop_orphan_table(tablename text)""".format(schema=ORPHAN_TABLES_SCHEMA)
        dbconn.execSQL(self.conn, REMOVE_DROP_ORPHAN_TABLE_FUNCTION)
        self.conn.commit()
        dbconn.execSQL(self.conn, REMOVE_CATDML_FUNCTION)
        self.conn.commit()

    def _remove_orphan_table_schema(self):
        REMOVE_ORPHAN_TABLE_SCHEMA = """ DROP SCHEMA {schema}""".format(schema=ORPHAN_TABLES_SCHEMA)
        dbconn.execSQL(self.conn, REMOVE_ORPHAN_TABLE_SCHEMA)
        self.conn.commit()

    def _run_drop_function(self, tablename):
        DROP_ORPHAN_TABLE_QUERY = """
        SELECT {schema}.drop_orphan_table('{tablename}');
        """.format(schema=ORPHAN_TABLES_SCHEMA, tablename=tablename)

        dbconn.execSQL(self.conn, DROP_ORPHAN_TABLE_QUERY) 
        self.conn.commit()

    def _drop_orphan_tables(self, orphan_table_list):
        try: 
            logger.info('Creating {schema} schema'.format(schema=ORPHAN_TABLES_SCHEMA))
            self._create_orphan_table_schema()

            logger.info('Creating functions to drop the tables on segments')
            self._create_drop_functions()
            for ot in orphan_table_list:
                logger.info('Dropping table {tablename} on segments'.format(tablename=ot))
                self._run_drop_function(ot)
        finally:
            logger.info('Cleaning up schema {schema}'.format(schema=ORPHAN_TABLES_SCHEMA))
            self._remove_drop_functions()
            self._remove_orphan_table_schema()
       
    def _read_tables(self, filename):
        tables = {}
        with open(filename, 'r') as fp:
            for line in fp:
                if line.startswith('DATABASE:'):
                    db = line.split(':')[-1]
                    tables[db] = []
                else:
                    tables[db].append(line.strip())
        return tables

    def _write_tables(self, filename, dbname, table_list):
        with open(filename, 'a') as fp:
            if not table_list:
                return
            fp.write('DATABASE:{dbname}\n'.format(dbname=dbname))
            for table in table_list:
                schemaname, tablename = table.split('.')
                fp.write('"{schemaname}"."{tablename}"\n'.format(schemaname=schemaname, tablename=tablename))
            
    def _validate_orphan_tables(self, orphan_table_list):
        VALIDATE_ORPHAN_TABLES_QUERY = """
        SELECT COUNT(*)
        FROM pg_class c, pg_namespace n
        WHERE c.relnamespace = n.oid
        AND n.nspname || '.' || c.relname IN ('{table_list}')
        """.format(table_list=','.join(map(lambda x: x.replace('"', ''), orphan_table_list)))
        res = dbconn.execSQLForSingleton(self.conn, VALIDATE_ORPHAN_TABLES_QUERY)
        if res != 0:
            raise Exception('Invalid table in table list')

    def run(self):
    
        if not self.table_file:
            if not self.dbnames:
                self.dbnames = self._get_all_databases()
            for db in self.dbnames:
                self._connect_to_db(db)
                logger.info('Generating list of orphan tables for database {dbname}'.format(dbname=db))
                orphan_table_list = self._generate_orphan_table_list()
                self._write_tables(ORPHAN_TABLES_FILE, db, orphan_table_list)
                self._close_connection()
            logger.info('*******************************************')
            logger.info('List of orphan tables has been written to {ofile}'.format(ofile=ORPHAN_TABLES_FILE))
            logger.info('Please review the file and run                ')
            logger.info('$GPHOME/share/postgresql/upgrade/fix_orphan_segment_tables.py -p <port> -f {ofile}'.format(ofile=ORPHAN_TABLES_FILE))
            logger.info('in order to drop the tables on the segments')
            logger.info('*******************************************')
        else:
            orphan_tables = self._read_tables(self.table_file)
            for db, orphan_table_list in orphan_tables.items():
                self._connect_to_db(db)
                self._validate_orphan_tables(orphan_table_list)
                logger.info('Proceeding to drop orphan tables on segments for database {dbname}'.format(dbname=db))
                self._drop_orphan_tables(orphan_table_list)
                self._close_connection()

    def cleanup(self):
        if self.conn:
            self.conn.close()
            self.conn = None

def create_parser():
    parser = OptParser(option_class=OptChecker,
                       version='%prog',
                       description='Drop orphan tables on segments')

    help_text = ["""
    This script drops all the orphan tables on the segments. i.e tables which
    exist on the segments but not on the master.  The script works in two
    phases. In the first phase, the script generates a file containing the list
    of orphan tables.  In the second phase the script takes the generated file
    as input and then performs the actual dropping of the tables on the
    segments.
    """,
    """
    In order to generate a list of all orphan tables for all databases in the
    system, run the script as follows :-
    """,
    """
    $GPHOME/share/postgresql/upgrade/fix_orphan_segment_tables.py -p <port>
    """,
    """
    In order to generate a list of all orphan tables for a single database, run
    the script as follows :-
    """,
    """
    $GPHOME/share/postgresql/upgrade/fix_orphan_segment_tables.py -p <port> -d <database>
    """,
    """
    The above command will generate a file containing the list of all orphan
    tables in the system. The name of the file will be of the form
    orphan_table_file_<timestamp> The file can be reviewed and edited if
    needed.
    """,
    """
    In order to actually drop the tables, run the script again as follows :-
    """,
    """
    $GPHOME/share/postgresql/upgrade/fix_orphan_segment_tables.py -p <port> -f <orphan_table_file_<timestamp>>
    """]

    parser.add_option('-f', '--table-file', dest='table_file', metavar='filename',
                      help='The name of the file containing the list of tables')
    parser.add_option('-d', '--database', dest='dbnames', metavar='database name',
                      action='append', help='The name of the database')
    parser.add_option('-p', '--port', dest='port', metavar='port',
                      help='The port of the database to connect to')
    
    addStandardLoggingAndHelpOptions(parser, includeNonInteractiveOption=True)
    parser.setHelp(help_text)
    return parser

if __name__ == '__main__':
    simple_main(create_parser, FixOrphanTables)
