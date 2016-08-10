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

from gppylib.commands.base import Command
import tinctest
from mpp.lib.PSQL import PSQL
from tinctest.lib import Gpdiff
from tinctest.lib.system import TINCSystem
import os
import sys
import unittest2 as unittest
from time import sleep
from mpp.gpdb.tests.utilities.upgrade.gpdb_upgrade import UpgradeTestCase
from tinctest.models.scenario import ScenarioTestCase
from mpp.gpdb.tests.storage.lib.gp_filedump import GpfileTestCase


class TruncatePrivUpgradeTestCase(ScenarioTestCase, UpgradeTestCase):
    '''
    Additonal upgrade tests for truncate privilege.
    @product_version gpdb: [4.3.4.1-]
    '''

    def setUp(self):
        self.upgrade_from = os.environ.get('UPGRADE_FROM', '4.2.6.3 2 sp')
        (self.old_gpdb, self.new_gpdb) = self.get_gpdbpath_info(self.upgrade_from)
        self.db_port = self.get_master_port()

    def tearDown(self):
        self.cleanup_upgrade(self.old_gpdb, self.new_gpdb, self.db_port, self.test_method)

    def test_upgrade_42_to_43(self):

        test_case_list0 = []
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.install_GPDB', [self.upgrade_from]))
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.setup_upgrade', {'old_version':self.upgrade_from, 'master_port': self.db_port, 'mirror_enabled' : True}))

        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.run_workload', ['test_truncate_priv'], {'db_port': self.db_port}))

        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.run_migrator', [self.old_gpdb, self.new_gpdb, self.db_port], {'mirror_enabled': True, 'migrator_option': '--skip-checkcat'}))
        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.validate_upgrade_correctness', [self.new_gpdb, self.db_port, self.test_method]))

        test_case_list0.append(('.gpdb_upgrade.UpgradeTestCase.validate_workload', ['test_truncate_priv'], {'db_port': self.db_port}))

        self.test_case_scenario.append(test_case_list0, serial=True)
