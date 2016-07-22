# AWS Preparation Script for Greenplum Database

This script configures software packages, kernel parameters, security settings and storage in preparation for GPDB installation.


## System Requirements

* `d2.8xlarge` EC2 instances (See [Hardware Setup](https://github.com/cfmobile/gpdb-aws/blob/master/manual/README.md#hardware-setup))

## Usage

```
Usage:
./prepare.sh </path/to/external/hostfile> [</path/to/internal/hostfile>]

Environment Variables:

AWS_KEYPAIR         - Path to AWS Key
```

## Quick Start

1. Create a hostfile, mapping each internal IP address to one hostname. For example:

	```
	10.0.0.219	mdw
	10.0.0.220	smdw
	10.0.0.221	sdw1
	10.0.0.222	sdw2
	10.0.0.37	sdw3
	10.0.0.244	sdw4
	10.0.0.10	etl1
	10.0.0.209	etl2
	```

1. If you are preparing the machines from an external network, create a
   second hostfile with the external IP addresses. For example:

	```
	55.1.2.29	mdw
	55.1.2.30	smdw
	55.1.2.31	sdw1
	55.1.2.32	sdw2
	55.1.2.33	sdw3
	55.1.2.34	sdw4
	55.1.2.35	etl1
	55.1.2.36	etl2
	```

1. Call the prepare script with the created hostfile(s) and your AWS
   keyfile

	```
	$ AWS_KEYPAIR=/path/to/pem ./prepare.sh /path/to/external/hostfile /path/to/internal/hostfile
	```

## Hostfile Convention

Ensure the hostfile conforms to the following convention:

| Hostname | Role                | Required |
| ---      | ---                 | ---      |
| mdw      | Master node         | Yes      |
| smdw     | Standby master node | No       |
| sdw*N*   | Segment node(s)     | No       |
| etl*N*   | ETL node(s)         | No       |
