## The ci/ directory

These directories each describe, for a particular platform or service, how to use
that platform to build and test the software.

For example, Concourse is the main platform on which we build and test GPDB4.

Concourse delegates or calls out to Pulse and the wix-packaging VM to accomplish
some testing and packaging that it cannot do itself currently.

The concourse directory does not contain infrastructure code for setting up a
Concourse instance. For indeed, the Concourse pipelines, task.yml's, and scripts
should work on any Concourse installation -- they aren't tied to a particular
Concourse deployment. Exceptions:

- These concourse pipelines expect to do the build all on Linux machines
- The build is still dependent on connection to the Pivotal intranet. Mostly for
  `make sync_tools` but also for sync'ing to dist and triggering Pulse

The pulse directory is not currently comprehensive; there are other repositories
which provide scripts which Pulse uses to test the GPDB installer files. Examples:

- https://github.com/Pivotal-DataFabric/GPDB-HAWQ-DynamicProvisioning
- https://github.com/Pivotal-DataFabric/pulse_ci_utilities
- https://github.com/Pivotal-DataFabric/pulse-build-scripts

The wix-packaging directory does contain infrastructure code, because the GPDB4
makefiles expect it to be running the service in a specific way: accessible over
SSH at a particular URL. Thus, the infrastructure definition is necessary for this
particular platform.