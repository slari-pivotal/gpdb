@gpcheckcat
Feature: gpcheckcat tests

  Scenario: gpcheckcat should drop leaked schemas
        Given database "leak" is dropped and recreated
        And the user runs the command "psql leak -f 'gppylib/test/behave/mgmt_utils/steps/data/gpcheckcat/create_temp_schema_leak.sql'" in the background without sleep
        And waiting "1" seconds
        Then read pid from file "gppylib/test/behave/mgmt_utils/steps/data/gpcheckcat/pid_leak" and kill the process
        And the temporary file "gppylib/test/behave/mgmt_utils/steps/data/gpcheckcat/pid_leak" is removed
        And waiting "2" seconds
        When the user runs "gpstop -ar"
        Then gpstart should return a return code of 0
        When the user runs "psql leak -f gppylib/test/behave/mgmt_utils/steps/data/gpcheckcat/leaked_schema.sql"
        Then psql should return a return code of 0
        And psql should print pg_temp_ to stdout
        And psql should print (1 row) to stdout
        When the user runs "gpcheckcat leak"
        Then gpchekcat should return a return code of 0
        And the user runs "psql leak -f gppylib/test/behave/mgmt_utils/steps/data/gpcheckcat/leaked_schema.sql"
        Then psql should return a return code of 0
        And psql should print (0 rows) to stdout
        And verify that the schema "good_schema" exists in "leak"
        And the user runs "dropdb leak"
        And verify that a log was created by gpcheckcat in the user's "gpAdminLogs" directory

  Scenario: gpcheckcat should report unique index violations
        Given database "test_index" is dropped and recreated
        And the user runs "psql test_index -f 'gppylib/test/behave/mgmt_utils/steps/data/gpcheckcat/create_unique_index_violation.sql'"
        Then psql should return a return code of 0
        And psql should not print (0 rows) to stdout
        When the user runs "gpcheckcat test_index"
        Then gpcheckcat should not return a return code of 0
        And gpcheckcat should print Table pg_compression has a violated unique index: pg_compression_compname_index to stdout
        And the user runs "dropdb test_index"
        And verify that a log was created by gpcheckcat in the user's "gpAdminLogs" directory

  Scenario: gpcheckcat should find owner error and produce timestamped repair scripts from -A (all databases) option
        Given database "db1" is dropped and recreated
        And database "db2" is dropped and recreated
        And the path "gpcheckcat.repair.*" is removed from current working directory
        And there is a "heap" table "gpadmin_tbl" in "db1" with data
        And there is a "heap" table "gpadmin_tbl" in "db2" with data
        And the user runs "psql db1 -f gppylib/test/behave/mgmt_utils/steps/data/gpcheckcat/create_user_wolf.sql"
        Then psql should return a return code of 0
        Given the user runs sql "alter table gpadmin_tbl OWNER TO wolf" in "db1" on first primary segment
        When the user runs "gpcheckcat -A"
        Then gpcheckcat should return a return code of 3
        Then gpcheckcat should print reported here: owner to stdout
        Then the path "gpcheckcat.repair.*" is found in cwd "1" times
        When the user runs "gpcheckcat -A"
        Then gpcheckcat should return a return code of 3
        Then gpcheckcat should print reported here: owner to stdout
        Then the path "gpcheckcat.repair.*" is found in cwd "2" times
        And the user runs "dropdb db1"
        And the user runs "dropdb db2"
        And the path "gpcheckcat.repair.*" is removed from current working directory
