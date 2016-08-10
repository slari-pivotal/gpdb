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
import sys

from gpdb_upgrade import UpgradeTestCase
from tinctest.models.scenario import ScenarioTestCase

upgrade_from = os.environ.get('UPGRADE_FROM', '4.2.6.0 2 sp')
binary_swap_from = os.environ.get('BINARY_SWAP_FROM', '4.3.2.1 2 rc')

class UAOUpgradeTestCase(ScenarioTestCase, UpgradeTestCase):
    """ 
        Additonal upgrade test related to UAO.
        Should be run as addition not as replacement of the
        mpp.gpdb.tests.utilities.upgrade.test_upgrade tests
        @product_version gpdb: [4.3.0.0-]
    """

    def setUp(self):
        (self.old_gpdb, self.new_gpdb) = self.get_gpdbpath_info(upgrade_from)
        self.db_port = self.get_master_port()    
        self.db_name = 'gptest'

    def tearDown(self):
        self.cleanup_upgrade(self.old_gpdb, self.new_gpdb, self.db_port, self.test_method)

    def test_upgrade_42_43_delete(self):

        test_case_list0 = []
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.install_GPDB', [upgrade_from]))
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.setup_upgrade', {'old_version':upgrade_from, 'master_port': self.db_port, 'mirror_enabled' : False}))

        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.run_workload', ['test_uao'], {'db_port': self.db_port}))

        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.run_migrator', [self.old_gpdb, self.new_gpdb, self.db_port], {'mirror_enabled' : False}))
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.validate_upgrade_correctness', [self.new_gpdb, self.db_port, self.test_method]))

        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.validate_workload', ['test_uao'], {'db_port': self.db_port}))
        self.test_case_scenario.append(test_case_list0, serial=True)

    def test_upgrade_42_43_delete_mirror(self):

        test_case_list0 = []
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.install_GPDB', [upgrade_from]))
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.setup_upgrade', {'old_version':upgrade_from, 'master_port': self.db_port, 'mirror_enabled' : True}))
        
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.run_workload', ['test_uao'], {'db_port': self.db_port}))
        
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.run_migrator', [self.old_gpdb, self.new_gpdb, self.db_port], {'mirror_enabled' : True}))
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.validate_upgrade_correctness', [self.new_gpdb, self.db_port, self.test_method]))

        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.validate_workload', ['test_uao'], {'db_port': self.db_port}))
        self.test_case_scenario.append(test_case_list0, serial=True)

    def upgrade_uao_42_43_gptoolkit(self, mirror_enabled):

        test_case_list0 = []
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.install_GPDB', [upgrade_from]))
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.setup_upgrade', {'old_version':upgrade_from, 'master_port':self.db_port, 'mirror_enabled':mirror_enabled}))

        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.run_workload', ['test_uao'], {'db_port': self.db_port, 'output_to_file': True}))

        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.run_migrator', [self.old_gpdb, self.new_gpdb, self.db_port], {'mirror_enabled' : mirror_enabled}))
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.validate_upgrade_correctness', [self.new_gpdb, self.db_port, self.test_method]))

        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.validate_workload', ['test_uao'], {'db_port': self.db_port}))

        test_case_list0.append(('mpp.gpdb.tests.utilities.upgrade.UpgradeHelperClass.verify_uao_gptoolkit_functions', [self.db_name, self.db_port]))
        self.test_case_scenario.append(test_case_list0, serial=True)
        

    def test_uao_upgrade_gptoolkit(self):
        self.upgrade_uao_42_43_gptoolkit(mirror_enabled=False)

    def test_uao_upgrade_gptoolkit(self):
        self.upgrade_uao_42_43_gptoolkit(mirror_enabled=True)

    def test_upgrade_42_43_backup(self):

        test_case_list0 = []
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.install_GPDB', [upgrade_from]))
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.setup_upgrade', {'old_version':upgrade_from, 'master_port': self.db_port, 'mirror_enabled' : False}))

        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.run_workload', ['test_uao'], {'db_port': self.db_port}))

        test_case_list0.append(('mpp.gpdb.tests.utilities.upgrade.UpgradeHelperClass.backup_db',[self.old_gpdb,self.db_port, self.db_name]))

        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.run_migrator', [self.old_gpdb, self.new_gpdb, self.db_port], {'mirror_enabled' : False}))
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.validate_upgrade_correctness', [self.new_gpdb, self.db_port, self.test_method]))

        test_case_list0.append(('mpp.gpdb.tests.utilities.upgrade.UpgradeHelperClass.incremental_backup',[self.old_gpdb,self.db_port, self.db_name, self.new_gpdb]))
        self.test_case_scenario.append(test_case_list0, serial=True)
