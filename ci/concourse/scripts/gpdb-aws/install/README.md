# AWS Installation Script for Greenplum Database

This script installs GPDB onto a set of provisioned and prepared EC2
instances.

## System Requirements

* Provisioned and prepared set of EC2 instances

## Usage

```
Usage:
./install.sh </path/to/external/hostfile> [</path/to/internal/hostfile>]

Environment Variables:

GREENPLUM_DB        - Path to Greenplum Data Computing Appliance Database Installer bin file
GREENPLUM_LOADERS   - Path to Greenplum Database Loaders (RHEL x86_64) zip file
GREENPLUM_CC        - Path to Greenplum Command Center (RHEL x86_64) zip file

AWS_KEYPAIR         - Path to AWS Key

SEGMENTS            - Number of segments per segment host (Default: 8)
```

## Hostfile Convention

Ensure the hostfile conforms to the following convention:

| Hostname | Role                | Required |
| ---      | ---                 | ---      |
| mdw      | Master node         | Yes      |
| sdw*N*   | Segment node(s)     | No       |
| etl*N*   | ETL node(s)         | No       |
