@netbackup_old_to_new
Feature: NetBackup Integration with GPDB

    @nbusetup76
    Scenario: Setup to load NBU libraries
        Given the NetBackup "7.6" libraries are loaded

    @nbusetup76_old
    Scenario: Setup to load NBU libraries
        Given the NetBackup "7.6" libraries are loaded for GPHOME "/data/greenplum-db-old/"

    @nbusetup75
    Scenario: Setup to load NBU libraries
        Given the NetBackup "7.5" libraries are loaded

    @nbusetup71
    #Scenario: Setup to load NBU libraries
    #    Given the NetBackup "7.1" libraries are loaded


##----------------------------------------------------------------------------------------------------
##---------------------------------- start part 1 dump      ------------------------------------------
##----------------------------------------------------------------------------------------------------
    @nbu_old_to_new_partI
    Scenario: 0 - start the old gpdb version with the old dump file format
        Given the old database is started

    @nbu_old_to_new_partI
    Scenario: 1 - Full Backup and Restore
        Given the test is initialized with database "bkdb1"
        And the netbackup params have been parsed
        And there is a "ao" table "public.ao_table" in "bkdb1" with data
        And there is a "ao" table "public.ao_table_comp" with compression "zlib" in "bkdb1" with data
        And there is a "ao" table "public.ao_index_table" in "bkdb1" with data
        And there is a "ao" table "public.ao_index_table_comp" with compression "zlib" in "bkdb1" with data
        And there is a "ao" partition table "public.ao_part_table" in "bkdb1" with data
        And there is a "ao" partition table "public.ao_part_table_comp" with compression "zlib" in "bkdb1" with data
        And there is a "co" table "public.co_table" in "bkdb1" with data
        And there is a "co" table "public.co_table_comp" with compression "zlib" in "bkdb1" with data
        And there is a "co" table "public.co_index_table" in "bkdb1" with data
        And there is a "co" table "public.co_index_table_comp" with compression "zlib" in "bkdb1" with data
        And there is a "co" partition table "public.co_part_table" in "bkdb1" with data
        And there is a "co" partition table "public.co_part_table_comp" with compression "zlib" in "bkdb1" with data
        And there is a "heap" table "public.heap_table" in "bkdb1" with data
        And there is a "heap" table "public.heap_index_table" in "bkdb1" with data
        And there is a "heap" partition table "public.heap_part_table" in "bkdb1" with data
        And there is a mixed storage partition table "part_mixed_1" in "bkdb1" with data
        When the user runs "gpcrondump -a -x bkdb1" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb1" is saved for verification

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 2 - Full Backup and Restore with --netbackup-block-size option
        Given the test is initialized with database "bkdb2"
        And the netbackup params have been parsed
        And there is a "ao" table "public.ao_table" in "bkdb2" with data
        And there is a "co" table "public.co_table" in "bkdb2" with data
        When the user runs "gpcrondump -a -x bkdb2 --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb2" is saved for verification

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 3 - Full Backup and Restore with --netbackup-keyword option
        Given the test is initialized with database "bkdb3"
        And the netbackup params have been parsed
        And there is a "ao" table "public.ao_table" in "bkdb3" with data
        And there is a "co" table "public.co_table" in "bkdb3" with data
        When the user runs "gpcrondump -a -x bkdb3 --netbackup-keyword foo" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb3" is saved for verification

    @nbu_old_to_new_partI
    Scenario: 4 - Full Backup and Restore with --netbackup-block-size and --netbackup-keyword options
        Given the test is initialized with database "bkdb4"
        And the netbackup params have been parsed
        And there is a "ao" table "public.ao_table" in "bkdb4" with data
        And there is a "co" table "public.co_table" in "bkdb4" with data
        When the user runs "gpcrondump -a -x bkdb4 --netbackup-block-size 4096 --netbackup-keyword foo" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb4" is saved for verification

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 5 - Full Backup and Restore with -u option
        Given the test is initialized with database "bkdb5"
        And the netbackup params have been parsed
        And there is a "ao" table "public.ao_table" in "bkdb5" with data
        And there is a "co" table "public.co_table" in "bkdb5" with data
        When the user runs "gpcrondump -a -x bkdb5 -u /tmp" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb5" is saved for verification

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 6 - Full Backup with option -t and Restore
        Given the test is initialized with database "bkdb6"
        And the netbackup params have been parsed
        And there is a "ao" table "public.ao_table" in "bkdb6" with data
        And there is a "co" table "public.co_table" in "bkdb6" with data
        When the user runs "gpcrondump -a -x bkdb6 -t public.co_table -t public.ao_table" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb6" is saved for verification
        When the user truncates "public.co_table" tables in "bkdb6"
        And the user truncates "public.ao_table" tables in "bkdb6"

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 7 - Full Backup with option -T and Restore
        Given the test is initialized with database "bkdb7"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb7" with data
        And there is a "ao" table "public.ao_table" in "bkdb7" with data
        And there is a "co" table "public.co_table" in "bkdb7" with data
        When the user runs "gpcrondump -a -x bkdb7 -T public.heap_table" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb7" is saved for verification

    @nbu_old_to_new_partI
    Scenario: 8 - Full Backup with option -s and Restore
        Given the test is initialized with database "bkdb8"
        And the netbackup params have been parsed
        And there is schema "schema_heap, schema_ao" exists in "bkdb8"
        And there is a "heap" table "schema_heap.heap_table" in "bkdb8" with data
        And there is a "ao" table "schema_ao.ao_table" in "bkdb8" with data
        And there is a backupfile of tables "schema_heap.heap_table, schema_ao.ao_table" in "bkdb8" exists for validation
        When the user runs "gpcrondump -a -x bkdb8 -s schema_heap --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored

    @nbu_old_to_new_partI
    Scenario: 9 - Full Backup with option -t and Restore after TRUNCATE on filtered tables
        Given the test is initialized with database "bkdb9"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb9" with data
        And there is a backupfile of tables "public.heap_table" in "bkdb9" exists for validation
        When the user runs "gpcrondump -a -x bkdb9 -t public.heap_table --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        When the user truncates "public.heap_table" tables in "bkdb9"

    @nbu_old_to_new_partI
    Scenario: 10 - Full Backup with option --exclude-table-file and Restore
        Given the test is initialized with database "bkdb10"
        And the netbackup params have been parsed
        And there is a "ao" table "public.ao_table" in "bkdb10" with data
        And there is a "co" table "public.co_table" in "bkdb10" with data
        And there is a backupfile of tables "public.co_table" in "bkdb10" exists for validation
        And there is a file "exclude_file" with tables "public.ao_table"
        When the user runs "gpcrondump -a -x bkdb10 --exclude-table-file exclude_file --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 11 - Full Backup with option --table-file and Restore
        Given the test is initialized with database "bkdb11"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb11" with data
        And there is a "ao" table "public.ao_table" in "bkdb11" with data
        And there is a "co" table "public.co_table" in "bkdb11" with data
        And there is a backupfile of tables "public.heap_table, public.ao_table" in "bkdb11" exists for validation
        And there is a file "include_file" with tables "public.ao_table|public.heap_table"
        When the user runs "gpcrondump -a -x bkdb11 --table-file include_file --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored

    @nbu_old_to_new_partI
    Scenario: 12 - Schema only restore of full backup
        Given the test is initialized with database "bkdb12"
        And the netbackup params have been parsed
        And there is schema "s1" exists in "bkdb12"
        And there is a "ao" table "s1.ao_table" in "bkdb12" with data
        And there is a "co" table "s1.co_table" in "bkdb12" with data
        And there is schema "s2" exists in "bkdb12"
        And there is a "ao" table "s2.ao_table" in "bkdb12" with data
        And there is a "co" table "s2.co_table" in "bkdb12" with data
        When the user runs "gpcrondump -a -x bkdb12" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 13 - Full Backup and Restore without compression
        Given the test is initialized with database "bkdb13"
        And the netbackup params have been parsed
        And there is schema "s1" exists in "bkdb13"
        And there is a "ao" table "s1.ao_table" in "bkdb13" with data
        And there is a "co" table "s1.co_table" in "bkdb13" with data
        When the user runs "gpcrondump -a -x bkdb13 -z --netbackup-block-size 1024 --netbackup-keyword foo" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb13" is saved for verification


    @nbu_old_to_new_partI
    Scenario: 14 - gpdbrestore with --table-file option
        Given the test is initialized with database "bkdb14"
        And the netbackup params have been parsed
        And there is a "ao" table "public.ao_table" in "bkdb14" with data
        And there is a "co" table "public.co_table" in "bkdb14" with data
        And there is a table-file "/tmp/table_file_foo" with tables "public.ao_table, public.co_table"
        When the user runs "gpcrondump -a -x bkdb14" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb14" is saved for verification

    @nbu_old_to_new_partI
    Scenario: 15 - Multiple full backup and restore from first full backup
        Given the test is initialized with database "bkdb15"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb15" with data
        And there is a "ao" table "public.ao_table" in "bkdb15" with data
        And there is a "co" table "public.co_table" in "bkdb15" with data
        When the user runs "gpcrondump -a -x bkdb15 --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb15" is saved for verification
        When the numbers "1" to "100" are inserted into "ao_table" tables in "bkdb15"
        And the user runs "gpcrondump -a -x bkdb15 --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0

    @nbu_old_to_new_partI
    Scenario: 16 - gpdbrestore with -T option
        Given the test is initialized with database "bkdb16"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb16" with data
        And there is a "ao" table "public.ao_table" in "bkdb16" with data
        When the user runs "gpcrondump -a -x bkdb16 --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb16" is saved for verification
        And database "bkdb16" is dropped and recreated

    @nbu_old_to_new_partI
    Scenario: 17 - gpdbrestore list_backup option with full timestamp
        Given the test is initialized with database "bkdb17"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb17" with data
        When the user runs "gpcrondump -a -x bkdb17 --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored

    @nbu_old_to_new_partI
    Scenario: 18 - gpdbrestore list_backup option with incremental backup
        Given the test is initialized with database "bkdb18"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb18" with data
        And there is a "ao" table "public.ao_table" in "bkdb18" with data
        And there is a "co" table "public.co_table" in "bkdb18" with data
        And there is a list to store the incremental backup timestamps
        When the user runs "gpcrondump -a -x bkdb18 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored in a list
        And table "public.ao_table" is assumed to be in dirty state in "bkdb18"
        When the user runs "gpcrondump -a --incremental -x bkdb18 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored in a list
        And table "public.co_table" is assumed to be in dirty state in "bkdb18"
        When the user runs "gpcrondump -a --incremental -x bkdb18 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the timestamp from gpcrondump is stored in a list

    @nbu_old_to_new_partI
    Scenario: 19 - User specified timestamp key for dump
        Given the test is initialized with database "bkdb19"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb19" with data
        And there is a "ao" table "public.ao_index_table" in "bkdb19" with data
        When the user runs gpcrondump with -k option on database "bkdb19" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And verify that report file with prefix " " under subdir " " has been backed up using netbackup
        And verify that cdatabase file with prefix " " under subdir " " has been backed up using netbackup
        And verify that state file with prefix " " under subdir " " has been backed up using netbackup
        And all the data from "bkdb19" is saved for verification

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 20 - Full Backup and Restore with --prefix option
        Given the test is initialized with database "bkdb20"
        And the netbackup params have been parsed
        And the prefix "foo" is stored
        And there is a "heap" table "public.heap_table" in "bkdb20" with data
        And there is a "ao" partition table "public.ao_part_table" in "bkdb20" with data
        And there is a backupfile of tables "public.heap_table, public.ao_part_table" in "bkdb20" exists for validation
        When the user runs "gpcrondump -a -x bkdb20 --prefix=foo --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And verify that report file with prefix "foo" under subdir " " has been backed up using netbackup
        And verify that cdatabase file with prefix "foo" under subdir " " has been backed up using netbackup
        And verify that state file with prefix "foo" under subdir " " has been backed up using netbackup

    @nbu_old_to_new_partI
    Scenario: 21 - Full Backup and Restore with -u and --prefix option
        Given the test is initialized with database "bkdb21"
        And the netbackup params have been parsed
        And the prefix "foo" is stored
        And there is a "heap" table "public.heap_table" in "bkdb21" with data
        And there is a "ao" table "public.ao_table" in "bkdb21" with data
        And there is a backupfile of tables "public.heap_table, public.ao_table" in "bkdb21" exists for validation
        When the user runs "gpcrondump -a -x bkdb21 --prefix=foo -u /tmp --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the subdir from gpcrondump is stored
        And the timestamp from gpcrondump is stored
        And verify that report file with prefix "foo" under subdir "/tmp" has been backed up using netbackup
        And verify that cdatabase file with prefix "foo" under subdir "/tmp" has been backed up using netbackup
        And verify that state file with prefix "foo" under subdir "/tmp" has been backed up using netbackup

    @nbu_old_to_new_partI
    Scenario: 22 - Restore database without prefix for a dump with prefix
        Given the test is initialized with database "bkdb22"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb22" with data
        And there is a "ao" table "public.ao_index_table" in "bkdb22" with data
        And there is a "ao" partition table "public.ao_part_table" in "bkdb22" with data
        When the user runs "gpcrondump -a -x bkdb22 --prefix=foo --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored

    @nbu_old_to_new_partI
    Scenario: 23 - Full Backup and Restore of external and ao table
        Given the test is initialized with database "bkdb23"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb23" with data
        And there is a "ao" table "public.ao_table" in "bkdb23" with data
        And there is a "co" table "public.co_table_ex" in "bkdb23" with data
        And there is an external table "ext_tab" in "bkdb23" with data for file "/tmp/ext_tab"
        And the user runs "psql -c 'CREATE LANGUAGE plpythonu' bkdb23"
        And there is a function "pymax" in "bkdb23"
        And the user runs "psql -c 'CREATE VIEW vista AS SELECT text 'Hello World' AS hello' bkdb23"
        And the user runs "psql -c 'COMMENT ON TABLE public.ao_table IS 'Hello World' bkdb23"
        And the user runs "psql -c 'CREATE ROLE foo_user' bkdb23"
        And the user runs "psql -c 'GRANT INSERT ON TABLE public.ao_table TO foo_user' bkdb23"
        And the user runs "psql -c 'ALTER TABLE ONLY public.ao_table ADD CONSTRAINT null_check CHECK (column1 <> NULL);' bkdb23"
        When the user runs "gpcrondump -a -x bkdb23 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb23" is saved for verification
        And database "bkdb23" is dropped and recreated
        And there is a file "restore_file23" with tables "public.ao_table|public.ext_tab"

    @nbu_old_to_new_partI
    Scenario: 24 - Full Backup and Restore filtering tables with post data objects
        Given the test is initialized with database "bkdb24"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb24" with data
        And there is a "heap" table "public.heap_table_ex" in "bkdb24" with data
        And there is a "ao" table "public.ao_table" in "bkdb24" with data
        And there is a "co" table "public.co_table_ex" in "bkdb24" with data
        And there is a "ao" table "public.ao_index_table" with index "ao_index" compression "None" in "bkdb24" with data
        And there is a "co" table "public.co_index_table" with index "co_index" compression "None" in "bkdb24" with data
        And there is a trigger "heap_trigger" on table "public.heap_table" in "bkdb24" based on function "heap_trigger_func"
        And there is a trigger "heap_ex_trigger" on table "public.heap_table_ex" in "bkdb24" based on function "heap_ex_trigger_func"
        And the user runs "psql -c 'ALTER TABLE ONLY public.heap_table ADD CONSTRAINT heap_table_pkey PRIMARY KEY (column1, column2, column3);' bkdb24"
        And the user runs "psql -c 'ALTER TABLE ONLY public.heap_table_ex ADD CONSTRAINT heap_table_pkey PRIMARY KEY (column1, column2, column3);' bkdb24"
        And the user runs "psql -c 'ALTER TABLE ONLY heap_table ADD CONSTRAINT heap_const_1 FOREIGN KEY (column1, column2, column3) REFERENCES heap_table_ex(column1, column2, column3);' bkdb24"
        And the user runs "psql -c """create rule heap_co_rule as on insert to heap_table where column1=100 do instead insert into co_table_ex values(27, 'restore', '2013-08-19');""" bkdb24"
        When the user runs "gpcrondump -a -x bkdb24 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb24" is saved for verification
        And there is a file "restore_file24" with tables "public.ao_table|public.ao_index_table|public.heap_table"
        When table "public.ao_index_table" is dropped in "bkdb24"
        And table "public.ao_table" is dropped in "bkdb24"
        And table "public.heap_table" is dropped in "bkdb24"
        And the index "bitmap_co_index" in "bkdb24" is dropped
        And the trigger "heap_ex_trigger" on table "public.heap_table_ex" in "bkdb24" is dropped

    @nbu_old_to_new_partI
    Scenario: 25 - Full Backup and Restore dropped database filtering tables with post data objects
        Given the test is initialized with database "bkdb25"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb25" with data
        And there is a "heap" table "public.heap_index_table" in "bkdb25" with data
        And there is a "ao" table "public.ao_table" in "bkdb25" with data
        And there is a "co" table "public.co_table_ex" in "bkdb25" with data
        And there is a "ao" table "public.ao_index_table" with index "ao_index" compression "None" in "bkdb25" with data
        And there is a "co" table "public.co_index_table" with index "co_index" compression "None" in "bkdb25" with data
        And there is a trigger "heap_trigger" on table "public.heap_table" in "bkdb25" based on function "heap_trigger_func"
        And the user runs "psql -c 'ALTER TABLE ONLY public.heap_table ADD CONSTRAINT heap_table_pkey PRIMARY KEY (column1, column2, column3);' bkdb25"
        And the user runs "psql -c 'ALTER TABLE ONLY public.heap_index_table ADD CONSTRAINT heap_table_pkey PRIMARY KEY (column1, column2, column3);' bkdb25"
        And the user runs "psql -c 'ALTER TABLE ONLY heap_table ADD CONSTRAINT heap_const_1 FOREIGN KEY (column1, column2, column3) REFERENCES heap_index_table(column1, column2, column3);' bkdb25"
        And the user runs "psql -c """create rule heap_ao_rule as on insert to heap_table where column1=100 do instead insert into ao_table values(27, 'restore', '2013-08-19');""" bkdb25"
        When the user runs "gpcrondump -a -x bkdb25 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb25" is saved for verification
        And there is a file "restore_file25" with tables "public.ao_table|public.ao_index_table|public.heap_table|public.heap_index_table"
        And database "bkdb25" is dropped and recreated
        And there is a trigger function "heap_trigger_func" on table "public.heap_table" in "bkdb25"

    @nbu_old_to_new_partI
    Scenario: 26 - Full backup and restore for table names with multibyte (chinese) characters
        Given the test is initialized with database "bkdb26"
        And the netbackup params have been parsed
        And the user runs "psql -f test/behave/mgmt_utils/steps/data/create_multi_byte_char_table_name.sql bkdb26"
        When the user runs "gpcrondump -a -x bkdb26 --netbackup-block-size 1024" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored

    @nbu_old_to_new_partI
    Scenario: 27 - Full Backup with option -T and Restore with exactly 1000 partitions
        Given the test is initialized with database "bkdb27"
        And the netbackup params have been parsed
        And there is a "ao" table "public.ao_table" in "bkdb27" with data
        And there is a "ao" table "public.ao_part_table" in "bkdb27" having "1000" partitions
        When the user runs "gpcrondump -a -x bkdb27 -T public.ao_part_table --netbackup-block-size 1024" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb27" is saved for verification

    @nbu_old_to_new_partI
    Scenario: 28 - Single table restore with shared sequence across multiple tables
        Given the test is initialized with database "bkdb28"
        And the netbackup params have been parsed
        And there is a sequence "shared_seq" in "bkdb28"
        And the user runs "psql -c """CREATE TABLE table1 (column1 INT4 DEFAULT nextval('shared_seq') NOT NULL, price NUMERIC);""" bkdb28"
        And the user runs "psql -c """CREATE TABLE table2 (column1 INT4 DEFAULT nextval('shared_seq') NOT NULL, price NUMERIC);""" bkdb28"
        And the user runs "psql -c 'CREATE TABLE table3 (column1 INT4)' bkdb28"
        And the user runs "psql -c 'CREATE TABLE table4 (column1 INT4)' bkdb28"
        And the user runs "psql -c 'INSERT INTO table1 (price) SELECT * FROM generate_series(1000,1009)' bkdb28"
        And the user runs "psql -c 'INSERT INTO table2 (price) SELECT * FROM generate_series(2000,2009)' bkdb28"
        And the user runs "psql -c 'INSERT INTO table3 SELECT * FROM generate_series(3000,3009)' bkdb28"
        And the user runs "psql -c 'INSERT INTO table4 SELECT * FROM generate_series(4000,4009)' bkdb28"
        When the user runs "gpcrondump -x bkdb28 -a --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb28" is saved for verification
        And the user runs "psql -c 'INSERT INTO table2 (price) SELECT * FROM generate_series(2010,2019)' bkdb28"
        And table "public.table1" is dropped in "bkdb28"

    @nbu_old_to_new_partI
    Scenario: 29 - Full backup and restore using gpcrondump with pg_class lock
        Given the test is initialized with database "bkdb29"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" with compression "None" in "bkdb29" with data and 1000000 rows
        And there is a "ao" partition table "public.ao_part_table" in "bkdb29" with data
        And there is a backupfile of tables "public.heap_table, public.ao_part_table" in "bkdb29" exists for validation
        When the user runs the "gpcrondump -a -x bkdb29" in a worker pool "w1" using netbackup
        And this test sleeps for "2" seconds
        And the "gpcrondump" has a lock on the pg_class table in "bkdb29"
        And the worker pool "w1" is cleaned up
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb29" is saved for verification

    @nbu_old_to_new_partI
    Scenario: 30 - Restore -T for full dump should restore metadata/postdata objects for tablenames with English and multibyte (chinese) characters
        Given the test is initialized with database "bkdb30"
        And the netbackup params have been parsed
        And there is a "ao" table "public.ao_index_table" with index "ao_index" compression "None" in "bkdb30" with data
        And there is a "co" table "public.co_index_table" with index "co_index" compression "None" in "bkdb30" with data
        And there is a "heap" table "public.heap_index_table" with index "heap_index" compression "None" in "bkdb30" with data
        And the user runs "psql -c 'ALTER TABLE ONLY public.heap_index_table ADD CONSTRAINT heap_index_table_pkey PRIMARY KEY (column1, column2, column3);' bkdb30"
        And the user runs "psql -f test/behave/mgmt_utils/steps/data/create_multi_byte_char_tables.sql bkdb30"
        And the user runs "psql -f test/behave/mgmt_utils/steps/data/primary_key_multi_byte_char_table_name.sql bkdb30"
        And the user runs "psql -f test/behave/mgmt_utils/steps/data/index_multi_byte_char_table_name.sql bkdb30"
        When the user runs "gpcrondump -a -x bkdb30 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the user runs "psql -f test/behave/mgmt_utils/steps/data/describe_multi_byte_char.sql bkdb30 > /tmp/describe_multi_byte_char_before"
        And the user runs "psql -c '\d public.ao_index_table' bkdb30 > /tmp/describe_ao_index_table_before"
        When there is a backupfile of tables "ao_index_table, co_index_table, heap_index_table" in "bkdb30" exists for validation
        And table "public.ao_index_table" is dropped in "bkdb30"
        And the user runs "psql -f test/behave/mgmt_utils/steps/data/drop_table_with_multi_byte_char.sql bkdb30"

    @nbu_old_to_new_partI
    Scenario: 31 - Full Backup and Restore with the master dump file missing
        Given the test is initialized with database "bkdb31"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb31" with data
        And there is a "ao" partition table "public.ao_part_table" in "bkdb31" with data
        When the user runs "gpcrondump -x bkdb31 -a --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb31" is saved for verification

    @nbu_old_to_new_partI
    Scenario: 32 - Full Backup and Restore with the master dump file missing without compression
        Given the test is initialized with database "bkdb32"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb32" with data
        And there is a "ao" partition table "public.ao_part_table" in "bkdb32" with data
        When the user runs "gpcrondump -x bkdb32 -z -a --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb32" is saved for verification

    @nbu_old_to_new_partI
    Scenario: 33 - Uppercase Database Name Full Backup and Restore using timestamp
        Given the test is initialized with database "bkdb33"
        And the netbackup params have been parsed
        And database "TESTING" is dropped and recreated
        And there is a "heap" table "public.heap_table" in "TESTING" with data
        And there is a "ao" partition table "public.ao_part_table" in "TESTING" with data
        And all the data from "TESTING" is saved for verification
        When the user runs "gpcrondump -x TESTING -a --netbackup-block-size 1024" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 34 - Verify that metadata files get backed up to NetBackup server
        Given the test is initialized with database "bkdb34"
        And the netbackup params have been parsed
        And there are no report files in "master_data_directory"
        And there are no status files in "segment_data_directory"
        And there is a "heap" table "public.heap_table" in "bkdb34" with data
        And there is a "ao" partition table "public.ao_part_table" in "bkdb34" with data
        And all the data from "bkdb34" is saved for verification
        When the user runs "gpcrondump -x bkdb34 -a -g -G --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And verify that report file with prefix " " under subdir " " has been backed up using netbackup
        And verify that cdatabase file with prefix " " under subdir " " has been backed up using netbackup
        And verify that state file with prefix " " under subdir " " has been backed up using netbackup
        And verify that config file with prefix " " under subdir " " has been backed up using netbackup
        And verify that global file with prefix " " under subdir " " has been backed up using netbackup

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 35 - Basic Incremental Backup and Restore with NBU
        Given the test is initialized with database "bkdb35"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb35" with data
        And there is a "ao" table "public.ao_table" in "bkdb35" with data
        When the user runs "gpcrondump -a -x bkdb35 -g -G --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        When the user runs "gpcrondump -a --incremental -x bkdb35 -g -G --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb35" is saved for verification

    @nbu_old_to_new_partI
    Scenario: 36 - Simple Plan File Test
        Given the test is initialized with database "bkdb36"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb36" with data
        And there is a "heap" partition table "public.heap_part_table" in "bkdb36" with data
        And there is a "ao" table "public.ao_table" in "bkdb36" with data
        And there is a "ao" partition table "public.ao_part_table" in "bkdb36" with data
        And there is a "co" table "public.co_table" in "bkdb36" with data
        And there is a "co" partition table "public.co_part_table" in "bkdb36" with data
        When the user runs "gpcrondump -a -x bkdb36 --netbackup-block-size 4096" using netbackup
        And gpcrondump should return a return code of 0
        And the timestamp is labeled "ts0"
        And the user runs "gpcrondump -a -x bkdb36 --incremental --netbackup-block-size 4096" using netbackup
        And gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the timestamp is labeled "ts1"
        And "dirty_list" file should be created under " "
        And table "public.co_table" is assumed to be in dirty state in "bkdb36"
        And partition "1" of partition table "co_part_table" is assumed to be in dirty state in "bkdb36" in schema "public"
        And the user runs "gpcrondump -a -x bkdb36 --incremental --netbackup-block-size 4096" using netbackup
        And gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the timestamp is labeled "ts2"
        And "dirty_list" file should be created under " "

##----------------------------------------------------------------------------------------------------
##---------------------------------- start part 1 restore --------------------------------------------
##----------------------------------------------------------------------------------------------------

    @nbu_old_to_new_partI
    Scenario: 0 - start the new gpdb version
        Given the new database is started

    @nbu_old_to_new_partI
    Scenario: 1 - Full Backup and Restore
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that the data of "68" tables in "bkdb1" is validated after restore

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 2 - Full Backup and Restore with --netbackup-block-size option
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp and options " --netbackup-block-size 1024 " using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that the data of "2" tables in "bkdb2" is validated after restore

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 3 - Full Backup and Restore with --netbackup-keyword option
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that the data of "2" tables in "bkdb3" is validated after restore

    @nbu_old_to_new_partI
    Scenario: 4 - Full Backup and Restore with --netbackup-block-size and --netbackup-keyword options
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp and options " --netbackup-block-size 4096 " using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that the data of "2" tables in "bkdb4" is validated after restore

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 5 - Full Backup and Restore with -u option
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp and options " -u /tmp " using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that the data of "2" tables in "bkdb5" is validated after restore

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 6 - Full Backup with option -t and Restore
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp and options " " without -e option using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that the data of "3" tables in "bkdb6" is validated after restore

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 7 - Full Backup with option -T and Restore
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that the data of "2" tables in "bkdb7" is validated after restore
        And verify that there is no table "public.heap_table" in "bkdb7"

    @nbu_old_to_new_partI
    Scenario: 8 - Full Backup with option -s and Restore
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "heap" table "schema_heap.heap_table" in "bkdb8" with data
        And verify that there is no table "schema_ao.ao_table" in "bkdb8"

    @nbu_old_to_new_partI
    Scenario: 9 - Full Backup with option -t and Restore after TRUNCATE on filtered tables
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp and options "--netbackup-block-size 2048" without -e option using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "heap" table "public.heap_table" in "bkdb9" with data

    @nbu_old_to_new_partI
    Scenario: 10 - Full Backup with option --exclude-table-file and Restore
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "co" table "public.co_table" in "bkdb10" with data
        And verify that there is no table "public.ao_table" in "bkdb10"

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 11 - Full Backup with option --table-file and Restore
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "heap" table "public.heap_table" in "bkdb11" with data
        And verify that there is a "ao" table "public.ao_table" in "bkdb11" with data
        And verify that there is no table "public.co_table" in "bkdb11"

    @nbu_old_to_new_partI
    Scenario: 12 - Schema only restore of full backup
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the table names in "bkdb12" is stored
        And the user runs gpdbrestore with the stored json timestamp and options " -S s1" using netbackup
        Then gpdbrestore should return a return code of 0
        And tables names should be identical to stored table names in "bkdb12" except "public.gpcrondump_history,s2.ao_table,s2.co_table"

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 13 - Full Backup and Restore without compression
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that the data of "2" tables in "bkdb13" is validated after restore


    @nbu_old_to_new_partI
    Scenario: 14 - gpdbrestore with --table-file option
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp and options "--table-file /tmp/table_file_foo" using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that the data of "2" tables in "bkdb14" is validated after restore
        And verify that the tuple count of all appendonly tables are consistent in "bkdb14"

    @nbu_old_to_new_partI
    Scenario: 15 - Multiple full backup and restore from first full backup
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that the data of "3" tables in "bkdb15" is validated after restore
        And verify that the tuple count of all appendonly tables are consistent in "bkdb15"

    @nbu_old_to_new_partI
    Scenario: 16 - gpdbrestore with -T option
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp and options "-T public.ao_table -a --netbackup-block-size 2048" without -e option using netbackup
        And gpdbrestore should return a return code of 0
        Then verify that there is no table "heap_table" in "bkdb16"
        And verify that there is a "ao" table "public.ao_table" in "bkdb16" with data

    @nbu_old_to_new_partI
    Scenario: 17 - gpdbrestore list_backup option with full timestamp
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored timestamp to print the backup set with options "--netbackup-block-size 2048" using netbackup
        Then gpdbrestore should return a return code of 2
        And gpdbrestore should print --list-backup is not supported for restore with full timestamps to stdout

    @nbu_old_to_new_partI
    Scenario: 18 - gpdbrestore list_backup option with incremental backup
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored timestamp to print the backup set with options " " using netbackup
        Then gpdbrestore should return a return code of 0
        Then "plan" file should be created under " "
        And verify that the list of stored timestamps is printed to stdout
        Then "plan" file is removed under " "
        When the user runs gpdbrestore with the stored timestamp to print the backup set with options "-a" using netbackup
        Then gpdbrestore should return a return code of 0
        Then "plan" file should be created under " "
        And verify that the list of stored timestamps is printed to stdout

    @nbu_old_to_new_partI
    Scenario: 19 - User specified timestamp key for dump
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that the data of "2" tables in "bkdb19" is validated after restore
        And verify that the tuple count of all appendonly tables are consistent in "bkdb19"

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 20 - Full Backup and Restore with --prefix option
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp and options "--prefix=foo --netbackup-block-size 2048" using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "heap" table "public.heap_table" in "bkdb20" with data
        And verify that there is a "ao" table "public.ao_part_table" in "bkdb20" with data

    @nbu_old_to_new_partI
    Scenario: 21 - Full Backup and Restore with -u and --prefix option
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp and options "-u /tmp --prefix=foo --netbackup-block-size 2048" using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "heap" table "public.heap_table" in "bkdb21" with data
        And verify that there is a "ao" table "public.ao_table" in "bkdb21" with data

    @nbu_old_to_new_partI
    Scenario: 22 - Restore database without prefix for a dump with prefix
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 2
        And gpdbrestore should print No object matched the specified predicate to stdout

    @nbu_old_to_new_partI
    Scenario: 23 - Full Backup and Restore of external and ao table
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp and options "--table-file restore_file23 --netbackup-block-size 2048" without -e option using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "ao" table "public.ao_table" in "bkdb23" with data
        And verify that there is a "external" table "public.ext_tab" in "bkdb23" with data
        And verify that there is a constraint "null_check" in "bkdb23"
        And verify that there is no table "public.heap_table" in "bkdb23"
        And verify that there is no table "public.co_table_ex" in "bkdb23"
        And verify that there is no view "vista" in "bkdb23"
        And verify that there is no procedural language "plpythonu" in "bkdb23"
        And the user runs "psql -c '\z' bkdb23"
        And psql should print foo_user=a/ to stdout
        And the user runs "psql -c '\df' bkdb23"
        And psql should not print pymax to stdout
        And verify that the data of "2" tables in "bkdb23" is validated after restore

    @nbu_old_to_new_partI
    Scenario: 24 - Full Backup and Restore filtering tables with post data objects
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp and options "--table-file restore_file24 --netbackup-block-size 4096" without -e option using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "ao" table "public.ao_table" in "bkdb24" with data
        And verify that there is a "ao" table "public.ao_index_table" in "bkdb24" with data
        And verify that there is a "heap" table "public.heap_table" in "bkdb24" with data
        And verify that there is a "heap" table "public.heap_table_ex" in "bkdb24" with data
        And verify that there is a "co" table "public.co_table_ex" in "bkdb24" with data
        And verify that there is a "co" table "public.co_index_table" in "bkdb24" with data
        And the user runs "psql -c '\d public.ao_index_table' bkdb24"
        And psql should print \"bitmap_ao_index\" bitmap \(column3\) to stdout
        And psql should print \"btree_ao_index\" btree \(column1\) to stdout
        And the user runs "psql -c '\d public.heap_table' bkdb24"
        And psql should print \"heap_table_pkey\" PRIMARY KEY, btree \(column1, column2, column3\) to stdout
        And psql should print heap_trigger AFTER INSERT OR DELETE OR UPDATE ON heap_table FOR EACH STATEMENT EXECUTE PROCEDURE heap_trigger_func\(\) to stdout
        And psql should print heap_co_rule AS\n.*ON INSERT TO heap_table\n.*WHERE new\.column1 = 100 DO INSTEAD  INSERT INTO co_table_ex \(column1, column2, column3\) to stdout
        And psql should print \"heap_const_1\" FOREIGN KEY \(column1, column2, column3\) REFERENCES heap_table_ex\(column1, column2, column3\) to stdout
        And the user runs "psql -c '\d public.co_index_table' bkdb24"
        And psql should not print bitmap_co_index to stdout
        And the user runs "psql -c '\d public.heap_table_ex' bkdb24"
        And psql should not print heap_ex_trigger to stdout
        And verify that the data of "7" tables in "bkdb24" is validated after restore

    @nbu_old_to_new_partI
    Scenario: 25 - Full Backup and Restore dropped database filtering tables with post data objects
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp and options "--table-file restore_file25 --netbackup-block-size 4096" without -e option using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "ao" table "public.ao_table" in "bkdb25" with data
        And verify that there is a "ao" table "public.ao_index_table" in "bkdb25" with data
        And verify that there is a "heap" table "public.heap_table" in "bkdb25" with data
        And verify that there is a "heap" table "public.heap_index_table" in "bkdb25" with data
        And verify that there is no table "public.co_table_ex" in "bkdb25"
        And verify that there is no table "public.co_index_table" in "bkdb25"
        And the user runs "psql -c '\d public.ao_index_table' bkdb25"
        And psql should print \"bitmap_ao_index\" bitmap \(column3\) to stdout
        And psql should print \"btree_ao_index\" btree \(column1\) to stdout
        And the user runs "psql -c '\d public.heap_table' bkdb25"
        And psql should print \"heap_table_pkey\" PRIMARY KEY, btree \(column1, column2, column3\) to stdout
        And psql should print heap_trigger AFTER INSERT OR DELETE OR UPDATE ON heap_table FOR EACH STATEMENT EXECUTE PROCEDURE heap_trigger_func\(\) to stdout
        And psql should print heap_ao_rule AS\n.*ON INSERT TO heap_table\n.*WHERE new\.column1 = 100 DO INSTEAD  INSERT INTO ao_table \(column1, column2, column3\) to stdout
        And psql should print \"heap_const_1\" FOREIGN KEY \(column1, column2, column3\) REFERENCES heap_index_table\(column1, column2, column3\) to stdout
        And verify that the data of "4" tables in "bkdb25" is validated after restore

    @nbu_old_to_new_partI
    Scenario: 26 - Full backup and restore for table names with multibyte (chinese) characters
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        When the user runs "psql -f test/behave/mgmt_utils/steps/data/select_multi_byte_char.sql bkdb26"
        Then psql should print 1000 to stdout

    @nbu_old_to_new_partI
    Scenario: 27 - Full Backup with option -T and Restore with exactly 1000 partitions
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that the data of "1" tables in "bkdb27" is validated after restore

    @nbu_old_to_new_partI
    Scenario: 28 - Single table restore with shared sequence across multiple tables
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp and options "-T public.table1 --netbackup-block-size 4096" without -e option using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "heap" table "public.table1" in "bkdb28" with data
        And the user runs "psql -c 'INSERT INTO table2 (price) SELECT * FROM generate_series(2020,2029)' bkdb28"
        And verify that there are no duplicates in column "column1" of table "public.table2" in "bkdb28"

    @nbu_old_to_new_partI
    Scenario: 29 - Full backup and restore using gpcrondump with pg_class lock
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "heap" table "public.heap_table" in "bkdb29" with data
        And verify that there is a "ao" table "public.ao_part_table" in "bkdb29" with data

    @nbu_old_to_new_partI
    Scenario: 30 - Restore -T for full dump should restore metadata/postdata objects for tablenames with English and multibyte (chinese) characters
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp and options "--table-file test/behave/mgmt_utils/steps/data/include_tables_with_metadata_postdata --netbackup-block-size 4096" without -e option using netbackup
        Then gpdbrestore should return a return code of 0
        When the user runs "psql -f test/behave/mgmt_utils/steps/data/select_multi_byte_char_tables.sql bkdb30"
        Then psql should print 1000 to stdout 4 times
        And verify that there is a "ao" table "ao_index_table" in "bkdb30" with data
        And verify that there is a "co" table "co_index_table" in "bkdb30" with data
        And verify that there is a "heap" table "heap_index_table" in "bkdb30" with data
        When the user runs "psql -f test/behave/mgmt_utils/steps/data/describe_multi_byte_char.sql bkdb30 > /tmp/describe_multi_byte_char_after"
        And the user runs "psql -c '\d public.ao_index_table' bkdb30 > /tmp/describe_ao_index_table_after"
        Then verify that the contents of the files "/tmp/describe_multi_byte_char_before" and "/tmp/describe_multi_byte_char_after" are identical
        And verify that the contents of the files "/tmp/describe_ao_index_table_before" and "/tmp/describe_ao_index_table_after" are identical
        And the file "/tmp/describe_multi_byte_char_before" is removed from the system
        And the file "/tmp/describe_multi_byte_char_after" is removed from the system
        And the file "/tmp/describe_ao_index_table_before" is removed from the system
        And the file "/tmp/describe_ao_index_table_after" is removed from the system

    @nbu_old_to_new_partI
    Scenario: 31 - Full Backup and Restore with the master dump file missing
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And gpdbrestore should print Backup for given timestamp was performed using NetBackup. Querying NetBackup server to check for the dump file. to stdout

    @nbu_old_to_new_partI
    Scenario: 32 - Full Backup and Restore with the master dump file missing without compression
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And gpdbrestore should print Backup for given timestamp was performed using NetBackup. Querying NetBackup server to check for the dump file. to stdout

    @nbu_old_to_new_partI
    Scenario: 33 - Uppercase Database Name Full Backup and Restore using timestamp
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And gpdbestore should not print Issue with analyze of to stdout
        And verify that there is a "heap" table "public.heap_table" in "TESTING" with data
        And verify that there is a "ao" table "public.ao_part_table" in "TESTING" with data

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 34 - Verify that metadata files get backed up to NetBackup server
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "heap" table "public.heap_table" in "bkdb34" with data
        And verify that there is a "ao" table "public.ao_part_table" in "bkdb34" with data

    @nbusmoke
    @nbu_old_to_new_partI
    Scenario: 35 - Basic Incremental Backup and Restore with NBU
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored json timestamp and options " --netbackup-block-size 4096 " using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "heap" table "public.heap_table" in "bkdb35" with data
        And verify that there is a "ao" table "public.ao_table" in "bkdb35" with data

    @nbu_old_to_new_partI
    Scenario: 36 - Simple Plan File Test
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored timestamp using netbackup
        And gpdbrestore should return a return code of 0
        Then "plan" file should be created under " "
        And the plan file is validated against "data/plan1"

##----------------------------------------------------------------------------------------------------
##---------------------------------- start part 2 dump ----------------------------------------------
##----------------------------------------------------------------------------------------------------
    @nbu_old_to_new_partII
    Scenario: 0 - start the old gpdb version with the old dump file format
        Given the old database is started

    @nbu_old_to_new_partII
    Scenario: 37 - Multiple Incremental backup and restore
        Given the test is initialized with database "bkdb37"
        And the netbackup params have been parsed
        And there is schema "testschema" exists in "bkdb37"
        And there is a "heap" table "public.heap_table" in "bkdb37" with data
        And there is a "heap" partition table "public.heap_part_table" in "bkdb37" with data
        And there is a "heap" table "testschema.heap_table" in "bkdb37" with data
        And there is a "heap" partition table "testschema.heap_part_table" in "bkdb37" with data
        And there is a "ao" table "public.ao_table" in "bkdb37" with data
        And there is a "ao" partition table "public.ao_part_table" in "bkdb37" with data
        And there is a "ao" table "testschema.ao_table" in "bkdb37" with data
        And there is a "ao" partition table "testschema.ao_part_table" in "bkdb37" with data
        And there is a "co" table "public.co_table" in "bkdb37" with data
        And there is a "co" partition table "public.co_part_table" in "bkdb37" with data
        And there is a "co" table "testschema.co_table" in "bkdb37" with data
        And there is a "co" partition table "testschema.co_part_table" in "bkdb37" with data
        And there is a list to store the incremental backup timestamps
        When the user runs "gpcrondump -a -x bkdb37 --netbackup-block-size 4096" using netbackup
        And gpcrondump should return a return code of 0
        And the full backup timestamp from gpcrondump is stored
        And table "testschema.ao_table" is assumed to be in dirty state in "bkdb37"
        And the user runs "gpcrondump -a -x bkdb37 --incremental --netbackup-block-size 4096" using netbackup
        And gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored in a list
        And partition "1" of partition table "co_part_table" is assumed to be in dirty state in "bkdb37" in schema "testschema"
        And table "testschema.heap_table" is dropped in "bkdb37"
        And the user runs "gpcrondump -a -x bkdb37 --incremental --netbackup-block-size 4096" using netbackup
        And gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored in a list
        And table "testschema.ao_table" is assumed to be in dirty state in "bkdb37"
        And the user runs "gpcrondump -a -x bkdb37 --incremental --netbackup-block-size 4096" using netbackup
        And gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the timestamp from gpcrondump is stored in a list
        And all the data from "bkdb37" is saved for verification

    @nbusmoke
    @nbu_old_to_new_partII
    Scenario: 38 - Non compressed incremental backup
        Given the test is initialized with database "bkdb38"
        And the netbackup params have been parsed
        And there is schema "testschema" exists in "bkdb38"
        And there is a "heap" table "testschema.heap_table" in "bkdb38" with data
        And there is a "ao" table "testschema.ao_table" in "bkdb38" with data
        And there is a "co" partition table "testschema.co_part_table" in "bkdb38" with data
        And there is a list to store the incremental backup timestamps
        When the user runs "gpcrondump -a -x bkdb38 -z --netbackup-block-size 4096" using netbackup
        And the full backup timestamp from gpcrondump is stored
        And gpcrondump should return a return code of 0
        And table "testschema.ao_table" is assumed to be in dirty state in "bkdb38"
        And the user runs "gpcrondump -a -x bkdb38 --incremental -z --netbackup-block-size 4096" using netbackup
        And gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored in a list
        And partition "1" of partition table "co_part_table" is assumed to be in dirty state in "bkdb38" in schema "testschema"
        And table "testschema.heap_table" is dropped in "bkdb38"
        And the user runs "gpcrondump -a -x bkdb38 --incremental -z --netbackup-block-size 4096" using netbackup
        And gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored in a list
        And table "testschema.ao_table" is assumed to be in dirty state in "bkdb38"
        And the user runs "gpcrondump -a -x bkdb38 --incremental -z --netbackup-block-size 4096" using netbackup
        And gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the timestamp from gpcrondump is stored in a list
        And all the data from "bkdb38" is saved for verification

    @nbu_old_to_new_partII
    Scenario: 39 - gpdbrestore -u option with incremental backup timestamp
        Given the test is initialized with database "bkdb39"
        And the netbackup params have been parsed
        And there is a "ao" table "public.ao_table" in "bkdb39" with data
        And there is a "co" table "public.co_table" in "bkdb39" with data
        When the user runs "gpcrondump -a -x bkdb39 -u /tmp --netbackup-block-size 4096" using netbackup
        And gpcrondump should return a return code of 0
        And table "public.ao_table" is assumed to be in dirty state in "bkdb39"
        When the user runs "gpcrondump -a -x bkdb39 -u /tmp --incremental --netbackup-block-size 4096" using netbackup
        And gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb39" is saved for verification

    @nbu_old_to_new_partII
    Scenario: 40 - Incremental backup with -T option
        Given the test is initialized with database "bkdb40"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb40" with data
        And there is a "ao" partition table "public.ao_part_table" in "bkdb40" with data
        And there is a "ao" table "public.ao_index_table" in "bkdb40" with data
        When the user runs "gpcrondump -a -x bkdb40 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And table "ao_index_table" is assumed to be in dirty state in "bkdb40"
        When the user runs "gpcrondump -a -x bkdb40 --incremental --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb40" is saved for verification

    @nbu_old_to_new_partII
    Scenario: 41 - Dirty File Scale Test
        Given the test is initialized with database "bkdb41"
        And the netbackup params have been parsed
        And there are "240" "heap" tables "public.heap_table" with data in "bkdb41"
        And there are "10" "ao" tables "public.ao_table" with data in "bkdb41"
        When the user runs "gpcrondump -a -x bkdb41 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        When table "public.ao_table_1" is assumed to be in dirty state in "bkdb41"
        And table "public.ao_table_2" is assumed to be in dirty state in "bkdb41"
        And all the data from "bkdb41" is saved for verification
        And the user runs "gpcrondump -a --incremental -x bkdb41 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the subdir from gpcrondump is stored
        And database "bkdb41" is dropped and recreated

    @nbu_old_to_new_partII
    Scenario: 42 - Dirty File Scale Test for partitions
        Given the test is initialized with database "bkdb42"
        And the netbackup params have been parsed
        And there are "240" "heap" tables "public.heap_table" with data in "bkdb42"
        And there is a "ao" partition table "public.ao_table" in "bkdb42" with data
        Then data for partition table "ao_table" with partition level "1" is distributed across all segments on "bkdb42"
        And verify that partitioned tables "ao_table" in "bkdb42" have 6 partitions
        When the user runs "gpcrondump -a -x bkdb42 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        When table "public.ao_table_1_prt_p1_2_prt_1" is assumed to be in dirty state in "bkdb42"
        And table "public.ao_table_1_prt_p1_2_prt_2" is assumed to be in dirty state in "bkdb42"
        And all the data from "bkdb42" is saved for verification
        And the user runs "gpcrondump -a --incremental -x bkdb42 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the subdir from gpcrondump is stored
        And database "bkdb42" is dropped and recreated

    @nbu_old_to_new_partII
    Scenario: 43 - Incremental table filter gpdbrestore
        Given the test is initialized with database "bkdb43"
        And the netbackup params have been parsed
        And there are "2" "heap" tables "public.heap_table" with data in "bkdb43"
        And there is a "ao" partition table "public.ao_part_table" in "bkdb43" with data
        And there is a "ao" partition table "public.ao_part_table1" in "bkdb43" with data
        Then data for partition table "ao_part_table" with partition level "1" is distributed across all segments on "bkdb43"
        Then data for partition table "ao_part_table1" with partition level "1" is distributed across all segments on "bkdb43"
        And verify that partitioned tables "ao_part_table" in "bkdb43" have 6 partitions
        And verify that partitioned tables "ao_part_table1" in "bkdb43" have 6 partitions
        When the user runs "gpcrondump -a -x bkdb43 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        When table "public.ao_part_table_1_prt_p1_2_prt_1" is assumed to be in dirty state in "bkdb43"
        And table "public.ao_part_table_1_prt_p1_2_prt_2" is assumed to be in dirty state in "bkdb43"
        And table "public.ao_part_table_1_prt_p2_2_prt_1" is assumed to be in dirty state in "bkdb43"
        And table "public.ao_part_table_1_prt_p2_2_prt_2" is assumed to be in dirty state in "bkdb43"
        And all the data from "bkdb43" is saved for verification
        And the user runs "gpcrondump -a --incremental -x bkdb43 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored

    @nbu_old_to_new_partII
    Scenario: 44 - Incremental table filter gpdbrestore with noplan option
        Given the test is initialized with database "bkdb44"
        And the netbackup params have been parsed
        And there are "2" "heap" tables "public.heap_table" with data in "bkdb44"
        And there is a "ao" partition table "public.ao_part_table" in "bkdb44" with data
        And there is a "ao" partition table "public.ao_part_table1" in "bkdb44" with data
        Then data for partition table "ao_part_table" with partition level "1" is distributed across all segments on "bkdb44"
        Then data for partition table "ao_part_table1" with partition level "1" is distributed across all segments on "bkdb44"
        And verify that partitioned tables "ao_part_table" in "bkdb44" have 6 partitions
        And verify that partitioned tables "ao_part_table1" in "bkdb44" have 6 partitions
        When the user runs "gpcrondump -a -x bkdb44 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        When all the data from "bkdb44" is saved for verification
        And the user runs "gpcrondump -a --incremental -x bkdb44 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the subdir from gpcrondump is stored
        And the timestamp from gpcrondump is stored
        And database "bkdb44" is dropped and recreated

    @nbu_old_to_new_partII
    Scenario: 45 - Multiple full and incrementals with and without prefix
        Given the test is initialized with database "bkdb45"
        And the netbackup params have been parsed
        And the prefix "foo" is stored
        And there is a list to store the incremental backup timestamps
        And there is a "heap" table "public.heap_table" in "bkdb45" with data
        And there is a "ao" table "public.ao_index_table" in "bkdb45" with data
        And there is a "ao" partition table "public.ao_part_table" in "bkdb45" with data
        When the user runs "gpcrondump -a -x bkdb45 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        When the user runs "gpcrondump -a -x bkdb45 --prefix=foo --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And table "public.ao_index_table" is assumed to be in dirty state in "bkdb45"
        When the user runs "gpcrondump -a -x bkdb45 --incremental --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And table "public.ao_index_table" is assumed to be in dirty state in "bkdb45"
        When the user runs "gpcrondump -a -x bkdb45 --incremental --prefix=foo --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the timestamp from gpcrondump is stored in a list
        And all the data from "bkdb45" is saved for verification

    @nbu_old_to_new_partII
    Scenario: 46 - Incremental Backup and Restore with --prefix and -u options
        Given the test is initialized with database "bkdb46"
        And the netbackup params have been parsed
        And the prefix "foo" is stored
        And there is a list to store the incremental backup timestamps
        And there is a "heap" table "public.heap_table" in "bkdb46" with data
        And there is a "ao" table "public.ao_index_table" in "bkdb46" with data
        And there is a "ao" partition table "public.ao_part_table" in "bkdb46" with data
        When the user runs "gpcrondump -a -x bkdb46 --prefix=foo -u /tmp --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the full backup timestamp from gpcrondump is stored
        And table "public.ao_index_table" is assumed to be in dirty state in "bkdb46"
        When the user runs "gpcrondump -a -x bkdb46 --incremental --prefix=foo -u /tmp --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the timestamp from gpcrondump is stored in a list
        And all the data from "bkdb46" is saved for verification

    @nbu_old_to_new_partII
    Scenario: 47 - Incremental Backup with table filter on Full Backup should update the tracker files
        Given the test is initialized with database "bkdb47"
        And the netbackup params have been parsed
        And the prefix "foo" is stored
        And there is a list to store the incremental backup timestamps
        And there is a "heap" table "public.heap_table" in "bkdb47" with data
        And there is a "heap" table "public.heap_index_table" in "bkdb47" with data
        And there is a "ao" table "public.ao_index_table" in "bkdb47" with data
        And there is a "ao" partition table "public.ao_part_table" in "bkdb47" with data
        When the user runs "gpcrondump -a -x bkdb47 --prefix=foo -t public.ao_index_table -t public.heap_table --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the full backup timestamp from gpcrondump is stored
        And "_filter" file should be created under " "
        And verify that the "filter" file in " " dir contains "public.ao_index_table"
        And verify that the "filter" file in " " dir contains "public.heap_table"
        And table "public.ao_index_table" is assumed to be in dirty state in "bkdb47"
        When the user runs "gpcrondump -a -x bkdb47 --prefix=foo --incremental --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the timestamp from gpcrondump is stored in a list
        And "public.ao_index_table" is marked as dirty in dirty_list file
        And "public.heap_table" is marked as dirty in dirty_list file
        And verify that there is no "public.heap_index_table" in the "dirty_list" file in " "
        And verify that there is no "public.ao_part_table" in the "dirty_list" file in " "
        And verify that there is no "public.heap_index_table" in the "table_list" file in " "
        And verify that there is no "public.ao_part_table" in the "table_list" file in " "
        And all the data from "bkdb47" is saved for verification

    @nbu_old_to_new_partII
    Scenario: 48 - Incremental Backup and Restore of specified post data objects
        Given the test is initialized with database "bkdb48"
        And the netbackup params have been parsed
        And there is schema "testschema" exists in "bkdb48"
        And there is a list to store the incremental backup timestamps
        And there is a "heap" table "testschema.heap_table" in "bkdb48" with data
        And there is a "heap" partition table "public.heap_part_table" in "bkdb48" with data
        And there is a "ao" table "testschema.ao_table" in "bkdb48" with data
        And there is a "ao" partition table "testschema.ao_part_table" in "bkdb48" with data
        And there is a "co" table "public.co_table" in "bkdb48" with data
        And there is a "co" partition table "public.co_part_table" in "bkdb48" with data
        And there is a "heap" table "public.heap_table_ex" in "bkdb48" with data
        And there is a "heap" partition table "public.heap_part_table_ex" in "bkdb48" with data
        And there is a "co" table "testschema.co_table_ex" in "bkdb48" with data
        And there is a "co" partition table "testschema.co_part_table_ex" in "bkdb48" with data
        And there is a "co" table "public.co_index_table" with index "co_index" compression "None" in "bkdb48" with data
        And the user runs "psql -c 'ALTER TABLE ONLY testschema.heap_table ADD CONSTRAINT heap_table_pkey PRIMARY KEY (column1, column2, column3);' bkdb48"
        And the user runs "psql -c 'ALTER TABLE ONLY heap_table_ex ADD CONSTRAINT heap_table_pkey PRIMARY KEY (column1, column2, column3);' bkdb48"
        And the user runs "psql -c 'ALTER TABLE ONLY testschema.heap_table ADD CONSTRAINT heap_const_1 FOREIGN KEY (column1, column2, column3) REFERENCES heap_table_ex(column1, column2, column3);' bkdb48"
        And the user runs "psql -c """create rule heap_co_rule as on insert to testschema.heap_table where column1=100 do instead insert into testschema.co_table_ex values(27, 'restore', '2013-08-19');""" bkdb48"
        When the user runs "gpcrondump -a -x bkdb48 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the full backup timestamp from gpcrondump is stored
        And table "public.co_table" is assumed to be in dirty state in "bkdb48"
        And partition "2" of partition table "ao_part_table" is assumed to be in dirty state in "bkdb48" in schema "testschema"
        When the user runs "gpcrondump -a -x bkdb48 --incremental --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the timestamp from gpcrondump is stored in a list
        And all the data from "bkdb48" is saved for verification
        And there is a file "restore_file48" with tables "testschema.heap_table|testschema.ao_table|public.co_table|testschema.ao_part_table"
        And table "testschema.heap_table" is dropped in "bkdb48"
        And table "testschema.ao_table" is dropped in "bkdb48"
        And table "public.co_table" is dropped in "bkdb48"
        And table "testschema.ao_part_table" is dropped in "bkdb48"
        When the index "bitmap_co_index" in "bkdb48" is dropped

    @nbu_old_to_new_partII
    Scenario: 49 - Restore -T for incremental dump should restore metadata/postdata objects for tablenames with English and multibyte (chinese) characters
        Given the test is initialized with database "bkdb49"
        And the netbackup params have been parsed
        And there is schema "schema_heap" exists in "bkdb49"
        And there is a "heap" table "schema_heap.heap_table" in "bkdb49" with data
        And there is a "ao" table "public.ao_index_table" with index "ao_index" compression "None" in "bkdb49" with data
        And there is a "co" table "public.co_index_table" with index "co_index" compression "None" in "bkdb49" with data
        And there is a "heap" table "public.heap_index_table" with index "heap_index" compression "None" in "bkdb49" with data
        And the user runs "psql -c 'ALTER TABLE ONLY public.heap_index_table ADD CONSTRAINT heap_index_table_pkey PRIMARY KEY (column1, column2, column3);' bkdb49"
        And the user runs "psql -f test/behave/mgmt_utils/steps/data/create_multi_byte_char_tables.sql bkdb49"
        And the user runs "psql -f test/behave/mgmt_utils/steps/data/primary_key_multi_byte_char_table_name.sql bkdb49"
        And the user runs "psql -f test/behave/mgmt_utils/steps/data/index_multi_byte_char_table_name.sql bkdb49"
        When the user runs "gpcrondump -a -x bkdb49 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And table "public.ao_index_table" is assumed to be in dirty state in "bkdb49"
        And the user runs "psql -f test/behave/mgmt_utils/steps/data/dirty_table_multi_byte_char.sql bkdb49"
        When the user runs "gpcrondump --incremental -a -x bkdb49 --netbackup-block-size 4096" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And the user runs "psql -f test/behave/mgmt_utils/steps/data/describe_multi_byte_char.sql bkdb49 > /tmp/describe_multi_byte_char_before"
        And the user runs "psql -c '\d public.ao_index_table' bkdb49 > /tmp/describe_ao_index_table_before"
        When there is a backupfile of tables "ao_index_table, co_index_table, heap_index_table" in "bkdb49" exists for validation
        And table "public.ao_index_table" is dropped in "bkdb49"
        And the user runs "psql -f test/behave/mgmt_utils/steps/data/drop_table_with_multi_byte_char.sql bkdb49"

    @nbu_old_to_new_partII
    Scenario: 50 - Incremental Backup with pre-content_id
        Given the test is initialized with database "bkdb50"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb50" with data
        And there is a "ao" table "public.ao_table" in "bkdb50" with data
        When the user runs "gpcrondump -a -x bkdb50 -g -G --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored

    @nbu_old_to_new_partII
    Scenario: 51 - Incremental with contentid after pre-contentid incremental
        Given the test is initialized with database "bkdb51"
        And the netbackup params have been parsed
        And there is a "heap" table "public.heap_table" in "bkdb51" with data
        And there is a "ao" table "public.ao_table" in "bkdb51" with data
        When the user runs "gpcrondump -a -x bkdb51 -g -G --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        When the user runs "gpcrondump -a --incremental -x bkdb51 -g -G --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored

##----------------------------------------------------------------------------------------------------
##---------------------------------- start part 2 restore      ---------------------------------------
##----------------------------------------------------------------------------------------------------

    @nbu_old_to_new_partII
    Scenario: 0 - start the new gpdb version
        Given the new database is started

    @nbu_old_to_new_partII
    Scenario: 37 - Multiple Incremental backup and restore
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is no table "testschema.heap_table" in "bkdb37"
        And verify that the data of "60" tables in "bkdb37" is validated after restore
        And verify that the tuple count of all appendonly tables are consistent in "bkdb37"
        And verify that the plan file is created for the latest timestamp

    @nbusmoke
    @nbu_old_to_new_partII
    Scenario: 38 - Non compressed incremental backup
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored timestamp using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is no table "testschema.heap_table" in "bkdb38"
        And verify that the data of "11" tables in "bkdb38" is validated after restore
        And verify that the tuple count of all appendonly tables are consistent in "bkdb38"
        And verify that the plan file is created for the latest timestamp

    @nbu_old_to_new_partII
    Scenario: 39 - gpdbrestore -u option with incremental backup timestamp
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored timestamp and options "-u /tmp --verbose" using netbackup
        And gpdbrestore should return a return code of 0
        Then verify that the data of "3" tables in "bkdb39" is validated after restore
        And verify that the tuple count of all appendonly tables are consistent in "bkdb39"

    @nbu_old_to_new_partII
    Scenario: 40 - Incremental backup with -T option
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored timestamp and options "-T public.ao_index_table" using netbackup
        And gpdbrestore should return a return code of 0
        Then verify that there is no table "ao_part_table" in "bkdb40"
        And verify that there is no table "public.heap_table" in "bkdb40"
        And verify that there is a "ao" table "public.ao_index_table" in "bkdb40" with data

    @nbu_old_to_new_partII
    Scenario: 41 - Dirty File Scale Test
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gp_restore with the the stored timestamp and subdir for metadata only in "bkdb41" using netbackup
        Then gp_restore should return a return code of 0
        When the user runs gpdbrestore with the stored timestamp and options "--noplan" without -e option using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that tables "public.ao_table_3, public.ao_table_4, public.ao_table_5, public.ao_table_6" in "bkdb41" has no rows
        And verify that tables "public.ao_table_7, public.ao_table_8, public.ao_table_9, public.ao_table_10" in "bkdb41" has no rows
        And verify that the data of the dirty tables under " " in "bkdb41" is validated after restore

    @nbu_old_to_new_partII
    Scenario: 42 - Dirty File Scale Test for partitions
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gp_restore with the the stored timestamp and subdir for metadata only in "bkdb42" using netbackup
        Then gp_restore should return a return code of 0
        When the user runs gpdbrestore with the stored timestamp and options "--noplan" without -e option using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that tables "public.ao_table_1_prt_p1_2_prt_3, public.ao_table_1_prt_p2_2_prt_1" in "bkdb42" has no rows
        And verify that tables "public.ao_table_1_prt_p2_2_prt_2, public.ao_table_1_prt_p2_2_prt_3" in "bkdb42" has no rows
        And verify that the data of the dirty tables under " " in "bkdb42" is validated after restore

    @nbu_old_to_new_partII
    Scenario: 43 - Incremental table filter gpdbrestore
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored timestamp and options "-T public.ao_part_table --netbackup-block-size 4096" using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is no table "public.ao_part_table1_1_prt_p1_2_prt_3" in "bkdb43"
        And verify that there is no table "public.ao_part_table1_1_prt_p2_2_prt_3" in "bkdb43"
        And verify that there is no table "public.ao_part_table1_1_prt_p1_2_prt_2" in "bkdb43"
        And verify that there is no table "public.ao_part_table1_1_prt_p2_2_prt_2" in "bkdb43"
        And verify that there is no table "public.ao_part_table1_1_prt_p1_2_prt_1" in "bkdb43"
        And verify that there is no table "public.ao_part_table1_1_prt_p2_2_prt_1" in "bkdb43"
        And verify that there is no table "public.heap_table_1" in "bkdb43"
        And verify that there is no table "public.heap_table_2" in "bkdb43"

    @nbu_old_to_new_partII
    Scenario: 44 - Incremental table filter gpdbrestore with noplan option
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gp_restore with the the stored timestamp and subdir for metadata only in "bkdb44" using netbackup
        Then gp_restore should return a return code of 0
        When the user runs gpdbrestore with the stored timestamp and options "-T public.ao_part_table -T public.heap_table_1 --noplan" without -e option using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that tables "public.ao_part_table_1_prt_p1_2_prt_3, public.ao_part_table_1_prt_p2_2_prt_3" in "bkdb44" has no rows
        And verify that tables "public.ao_part_table_1_prt_p1_2_prt_2, public.ao_part_table_1_prt_p2_2_prt_2" in "bkdb44" has no rows
        And verify that tables "public.ao_part_table_1_prt_p1_2_prt_1, public.ao_part_table_1_prt_p2_2_prt_1" in "bkdb44" has no rows
        And verify that tables "public.ao_part_table1_1_prt_p1_2_prt_3, public.ao_part_table1_1_prt_p2_2_prt_3" in "bkdb44" has no rows
        And verify that tables "public.ao_part_table1_1_prt_p1_2_prt_2, public.ao_part_table1_1_prt_p2_2_prt_2" in "bkdb44" has no rows
        And verify that tables "public.ao_part_table1_1_prt_p1_2_prt_1, public.ao_part_table1_1_prt_p2_2_prt_1" in "bkdb44" has no rows
        And verify that there is a "heap" table "public.heap_table_1" in "bkdb44" with data

    @nbu_old_to_new_partII
    Scenario: 45 - Multiple full and incrementals with and without prefix
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored timestamp and options "--prefix=foo --netbackup-block-size 4096" using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that the data of "12" tables in "bkdb45" is validated after restore

    @nbu_old_to_new_partII
    Scenario: 46 - Incremental Backup and Restore with --prefix and -u options
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored timestamp and options "--prefix=foo -u /tmp --netbackup-block-size 4096" using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that the data of "12" tables in "bkdb46" is validated after restore

    @nbu_old_to_new_partII
    Scenario: 47 - Incremental Backup with table filter on Full Backup should update the tracker files
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored timestamp and options "--prefix=foo --netbackup-block-size 4096" using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "heap" table "public.heap_table" in "bkdb47" with data
        And verify that there is a "ao" table "public.ao_index_table" in "bkdb47" with data
        And verify that there is no table "public.ao_part_table" in "bkdb47"
        And verify that there is no table "public.heap_index_table" in "bkdb47"

    @nbu_old_to_new_partII
    Scenario: 48 - Incremental Backup and Restore of specified post data objects
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored timestamp and options "--table-file restore_file48 --netbackup-block-size 4096" without -e option using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "heap" table "testschema.heap_table" in "bkdb48" with data
        And verify that there is a "ao" table "testschema.ao_table" in "bkdb48" with data
        And verify that there is a "co" table "public.co_table" in "bkdb48" with data
        And verify that there is a "ao" table "testschema.ao_part_table" in "bkdb48" with data
        And verify that there is a "heap" table "public.heap_table_ex" in "bkdb48" with data
        And verify that there is a "co" table "testschema.co_table_ex" in "bkdb48" with data
        And verify that there is a "heap" table "public.heap_part_table_ex" in "bkdb48" with data
        And verify that there is a "co" table "testschema.co_part_table_ex" in "bkdb48" with data
        And verify that there is a "co" table "public.co_part_table" in "bkdb48" with data
        And verify that there is a "heap" table "public.heap_part_table" in "bkdb48" with data
        And verify that there is a "co" table "public.co_index_table" in "bkdb48" with data
        And the user runs "psql -c '\d testschema.heap_table' bkdb48"
        And psql should print \"heap_table_pkey\" PRIMARY KEY, btree \(column1, column2, column3\) to stdout
        And psql should print heap_co_rule AS\n.*ON INSERT TO testschema.heap_table\n.*WHERE new\.column1 = 100 DO INSTEAD  INSERT INTO testschema.co_table_ex \(column1, column2, column3\) to stdout
        And psql should print \"heap_const_1\" FOREIGN KEY \(column1, column2, column3\) REFERENCES heap_table_ex\(column1, column2, column3\) to stdout
        And the user runs "psql -c '\d public.co_index_table' bkdb48"
        And psql should not print bitmap_co_index to stdout
        And verify that the data of "52" tables in "bkdb48" is validated after restore

    @nbu_old_to_new_partII
    Scenario: 49 - Restore -T for incremental dump should restore metadata/postdata objects for tablenames with English and multibyte (chinese) characters
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs gpdbrestore with the stored timestamp and options "--table-file test/behave/mgmt_utils/steps/data/include_tables_with_metadata_postdata --netbackup-block-size 4096" without -e option using netbackup
        Then gpdbrestore should return a return code of 0
        When the user runs "psql -f test/behave/mgmt_utils/steps/data/select_multi_byte_char_tables.sql bkdb49"
        Then psql should print 2000 to stdout 4 times
        And verify that there is a "ao" table "ao_index_table" in "bkdb49" with data
        And verify that there is a "co" table "co_index_table" in "bkdb49" with data
        And verify that there is a "heap" table "heap_index_table" in "bkdb49" with data
        When the user runs "psql -f test/behave/mgmt_utils/steps/data/describe_multi_byte_char.sql bkdb49 > /tmp/describe_multi_byte_char_after"
        And the user runs "psql -c '\d public.ao_index_table' bkdb49 > /tmp/describe_ao_index_table_after"
        Then verify that the contents of the files "/tmp/describe_multi_byte_char_before" and "/tmp/describe_multi_byte_char_after" are identical
        And verify that the contents of the files "/tmp/describe_ao_index_table_before" and "/tmp/describe_ao_index_table_after" are identical
        And the file "/tmp/describe_multi_byte_char_before" is removed from the system
        And the file "/tmp/describe_multi_byte_char_after" is removed from the system
        And the file "/tmp/describe_ao_index_table_before" is removed from the system
        And the file "/tmp/describe_ao_index_table_after" is removed from the system

    @nbu_old_to_new_partII
    Scenario: 50 - Incremental Backup with pre-content_id
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs "gpcrondump -a --incremental -x bkdb50 -g -G --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb50" is saved for verification
        When the user runs gpdbrestore with the stored json timestamp and options " --netbackup-block-size 4096 " using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "heap" table "public.heap_table" in "bkdb50" with data
        And verify that there is a "ao" table "public.ao_table" in "bkdb50" with data

    @nbu_old_to_new_partII
    Scenario: 51 - Incremental with contentid after pre-contentid incremental
        Given the netbackup params have been parsed
        And read old timestamp from json
        When the user runs "gpcrondump -a --incremental -x bkdb51 -g -G --netbackup-block-size 2048" using netbackup
        Then gpcrondump should return a return code of 0
        And the timestamp from gpcrondump is stored
        And all the data from "bkdb51" is saved for verification
        When the user runs gpdbrestore with the stored json timestamp and options " --netbackup-block-size 4096 " using netbackup
        Then gpdbrestore should return a return code of 0
        And verify that there is a "heap" table "public.heap_table" in "bkdb51" with data
        And verify that there is a "ao" table "public.ao_table" in "bkdb51" with data
