@gpinitsystem
Feature: Tests for gpinitsystem feature

    # Important: below assumes running within docker, where gpdemo has been copied to ~/gpdemo/
    @gpinitsystem_standby_failure_is_only_warning
    Scenario: gpinitsystem should warn but not fail when standby cannot be instantiated
        Given the database is running
        And all the segments are running
        And the segments are synchronized
        And the standby is not initialized
        And the cluster is stopped and cluster config is regenerated only
        And the user runs command "rm -rf /tmp/gpinitsystemtest && mkdir /tmp/gpinitsystemtest"
        When the user runs "gpinitsystem -a -c $HOME/gpdemo/clusterConfigFile -l /tmp/gpinitsystemtest -s localhost -P 21100 -F intentional_nonexistent_filespace:/wrong/path -h $HOME/gpdemo/hostfile"
        Then gpinitsystem should return a return code of 1
        And gpinitsystem should not print "To activate the Standby Master Segment in the event of Master" to stdout
        And gpinitsystem should print "Cluster setup finished, but Standby Master failed to initialize. Review contents of log files for errors." to stdout
        And sql "select * from gp_toolkit.__gp_user_namespaces" is executed in "postgres" db

    @gpinitsystem_standby_added
    Scenario: gpinitsystem should warn but not fail when standby cannot be instantiated
        Given the database is running
        And all the segments are running
        And the segments are synchronized
        And the standby is not initialized
        And the user runs command "rm -rf $MASTER_DATA_DIRECTORY/newstandby"
        And the user runs command "rm -rf /tmp/gpinitsystemtest && mkdir /tmp/gpinitsystemtest"
        And the cluster is stopped and cluster config is regenerated only
        When the user runs "gpinitsystem -a -c $HOME/gpdemo/clusterConfigFile -l /tmp/gpinitsystemtest -s localhost -P 21100 -F pg_system:$MASTER_DATA_DIRECTORY/newstandby -h $HOME/gpdemo/hostfile"
        Then gpinitsystem should return a return code of 0
        And gpinitsystem should print "Log file scan check passed" to stdout
        And sql "select * from gp_toolkit.__gp_user_namespaces" is executed in "postgres" db
