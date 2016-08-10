"""
Copyright (C) 2004-2015 Pivotal Software, Inc. All rights reserved.

This program and the accompanying materials are made available under
the terms of the under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

import os
import socket
import re
import tinctest
from gppylib.db import dbconn
from tinctest.lib import run_shell_command, local_path
from mpp.models import MPPTestCase
from mpp.lib.PSQL import PSQL

from mpp.gpdb.tests.storage.lib.gp_filedump import GpfileTestCase

class UpgradeHelperClass(MPPTestCase):

    def create_standby(self, old_gpdb, new_gpdb, db_port):
        host = socket.gethostname()
        mdd = os.path.join(old_gpdb , 'master/gpseg-1')
        standby_mdd = os.path.join(old_gpdb , 'master/gpseg-1/new')
        standby_port = db_port + 1

        cmdStr="export MASTER_DATA_DIRECTORY=%s; export PGPORT=%s; source %s;gpinitstandby -s %s -a -F 'pg_system:%s' -P %s" % (mdd, db_port, new_gpdb + '/greenplum_path.sh', host, standby_mdd, standby_port)
        res = {'rc':0, 'stderr':'', 'stdout':''}
        run_shell_command (cmdStr, 'run gpinitstandby', res)
        if res['rc'] > 0:
            raise Exception("Gpinitstandby failed")
    

    def backup_db(self, old_gpdb, db_port, db_name, options=" ", new_gpdb=None, mdd=None):
        if not mdd:
            mdd = os.path.join(old_gpdb , 'master/gpseg-1')
        if new_gpdb:
            cmdStr = "export MASTER_DATA_DIRECTORY=%s; export PGPORT=%s; source %s;gpcrondump -x %s -a %s" % (mdd, db_port, new_gpdb + '/greenplum_path.sh', db_name, options)
        else:
            cmdStr = "export MASTER_DATA_DIRECTORY=%s; export PGPORT=%s; source %s;gpcrondump -x %s -a %s" % (mdd, db_port, old_gpdb + '/greenplum-db/greenplum_path.sh', db_name, options)
        res = {'rc':0, 'stderr':'', 'stdout':''}
        run_shell_command (cmdStr, 'run gpcrondump', res)
        if res['rc'] > 0:
            raise Exception("gpcrondump failed with rc %s" % res['rc'])
        return res
        
    def restore_db(self, old_gpdb, new_gpdb, db_port, db_name, mdd=None):
        
        if not mdd:
            mdd = os.path.join(old_gpdb , 'master/gpseg-1')
        cmdStr="export MASTER_DATA_DIRECTORY=%s; export PGPORT=%s;export PGDATABASE=%s;source %s;gpdbrestore -e -s %s -a" % (mdd, db_port, 'gptest',  new_gpdb + '/greenplum_path.sh', db_name)
        res = {'rc':0, 'stderr':'', 'stdout':''}
        run_shell_command (cmdStr, 'run gpdbrestore', res)
        if res['rc'] > 0:
            raise Exception("gpdbrestore failed with rc %s" % res['rc'])
        return res

    def check_gpfiledump(self, old_gpdb, new_gpdb, db_port, checksum=False):
        gpfile = GpfileTestCase()

        if checksum == True:
            flag = " -M "
        else:
            flag = " "
        mdd = old_gpdb + 'master/gpseg-1'

        os.environ["MASTER_DATA_DIRECTORY"] = mdd
        os.environ["PGPORT"] =str(db_port)
        os.environ["GPHOME"] =new_gpdb

        (host, db_path) = gpfile.get_host_and_db_path('dldb')
        file_list = gpfile.get_relfile_list('dldb', 'delta_t1', db_path, host)
        for i in range(0, len(file_list)-2): # not for the .0 node and text column
            self.assertTrue(gpfile.check_in_filedump(db_path, host, file_list[i], 'HAS_DELTA_COMPRESSION', flag) , 'Delta compression not applied to new inserts')


    def verify_uao_gptoolkit_functions(self, dbname, db_port):
        """
            Checks if the UAO related gptoolkit functions have been
            installed correctly.
        """
        def has_zero_rows(sql):
            o = PSQL.run_sql_command(sql, dbname=dbname, port=db_port)
            return o.find("(0 rows)") >= 0
        def has_rows(sql):
            o = PSQL.run_sql_command(sql, dbname=dbname, port=db_port)
            return (o.find("rows)") >= 0 and o.find("(0 rows)") < 0) or o.find("(1 row)") >= 0
        def get_oid(table_name):
            s = PSQL.run_sql_command("SELECT oid from pg_class WHERE relname = '%s'" % table_name,
                dbname=dbname, port=db_port)
            if s.find("(0 rows)") >= 0:
                raise Exception("Table %s not found" % (table_name))
            line = s.splitlines()[3]
            return int(line)
        oid = get_oid('ao');
        oidcs = get_oid('aocs');

        print

        self.assertTrue(has_rows('SELECT * FROM gp_toolkit.__gp_aoseg_history(%s)' % oid))
        self.assertTrue(has_rows('SELECT * FROM gp_toolkit.__gp_aocsseg(%s)' % oidcs))
        self.assertTrue(has_rows("SELECT * FROM gp_toolkit.__gp_aocsseg_name('aocs')"))
        self.assertTrue(has_rows('SELECT * FROM gp_toolkit.__gp_aocsseg_history(%s)' % oidcs))
        self.assertTrue(has_rows('SELECT * FROM gp_toolkit.__gp_aoseg_history(%s)' % oid))
        self.assertTrue(has_zero_rows('SELECT * FROM gp_toolkit.__gp_aovisimap(%s)' % oid))
        self.assertTrue(has_zero_rows("SELECT * FROM gp_toolkit.__gp_aovisimap_name('ao')"))
        self.assertTrue(has_rows('SELECT * FROM gp_toolkit.__gp_aovisimap_hidden_info(%s)' % oid))
        self.assertTrue(has_rows("SELECT * FROM gp_toolkit.__gp_aovisimap_hidden_info_name('ao')"))
        self.assertTrue(has_zero_rows('SELECT * FROM gp_toolkit.__gp_aovisimap_entry(%s)' % oid))
        self.assertTrue(has_zero_rows("SELECT * FROM gp_toolkit.__gp_aovisimap_entry_name('ao')"))
        self.assertTrue(has_rows("SELECT * FROM gp_toolkit.__gp_aoseg_name('ao')"))


    def get_backup_state(self, stdout):
        """
        Helper function to search for the backup state information
        in the file system.
        """
        timestamp = None
        directory = None
        pattern1 = re.compile(r"Dump process command line.*--gp-r=(\S+) --gp-s=p")
        pattern2 = re.compile(r"Timestamp key = (\d{14})")

        for line in stdout.splitlines():
            m = pattern1.search(line)
            if m:
                directory = m.group(1)
            m = pattern2.search(line)
            if m:
                timestamp = m.group(1)
    
        return (directory, timestamp)

    def get_dirty_file(self, stdout):
        """
        Gets the contents of the dirty list file.
        """
        (directory, timestamp) = self.get_backup_state(stdout)
        filename = os.path.join(directory, "gp_dump_%s_dirty_list" % timestamp)
        return open(filename).read()

    def incremental_backup(self, old_gpdb, db_port, dbname, new_gpdb):
        result = self.backup_db(old_gpdb, db_port, dbname, options = '--incremental', new_gpdb=new_gpdb)
        # The state file should be empty
        dirty_file_state = self.get_dirty_file(result['stdout'])
        self.assertTrue(len(dirty_file_state.strip()) == 0)        


    def run_SQLQuery(self, exec_sql, dbname='postgres', port=0):
        with dbconn.connect(dbconn.DbURL(dbname=dbname, port=port)) as conn:
            curs = dbconn.execSQL(conn, exec_sql)
            results = curs.fetchall()
        return results


    def create_filespace(self, fsname, mdd, db_port, gphome):

        fs_sql = "select * from pg_filespace where fsname='%s'" % fsname.strip()
        fs_list = self.run_SQLQuery(fs_sql, dbname = 'template1', port= db_port)
        if len(fs_list) != 1 :
            config_sql = "select dbid, role, hostname, fselocation from gp_segment_configuration, pg_filespace_entry where fsedbid = dbid; "
            config = self.run_SQLQuery(config_sql, dbname = 'template1', port=db_port)
            file_config = local_path('%s_config' % fsname)
            f1 = open(file_config , "w")
            f1.write('filespace:%s\n' % fsname)
            for record in config:
                if record[1] == 'p':
                    fileloc = '%s/%s/primary' % (os.path.split(record[3])[0], fsname)
                else:
                    fileloc = '%s/%s/mirror' % (os.path.split(record[3])[0], fsname)
                cmd = "gpssh -h %s -e 'rm -rf %s; mkdir -p %s'"  % (record[2], fileloc, fileloc)
                run_shell_command(cmd)
                f1.write("%s:%s:%s/%s\n" % (record[2], record[0], fileloc, os.path.split(record[3])[1]))
            f1.close()
            fs_cmd = 'export MASTER_DATA_DIRECTORY=%s;export PGPORT=%s;%s/bin/gpfilespace -c %s' % (mdd, db_port, gphome, file_config)
            res = {'rc':0, 'stderr':'', 'stdout':''}
            run_shell_command (fs_cmd, 'Create filespace', res)
            if res['rc'] > 0:
                raise Exception("Filespace creation failed")

class NewEnv(object):
    def __init__(self, **kwargs):
        self.args = kwargs

    def __enter__(self):
        orig = dict()
        for key, val in self.args.items():
            if key in os.environ:
                orig[key] = os.environ[key]
            os.environ[key] = val
        self.orig = orig

    def __exit__(self, type, value, traceback):
        for key in self.args.keys():
            if key in self.orig:
                os.environ[key] = self.orig[key]
            else: 
                del os.environ[key]
