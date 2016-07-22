# AWS Provision Script for Greenplum Database

This script provisions EC2 instances in preparation for GPDB
installation.

## Requirements

* AWS Access Key and AWS Secret Key
* AWS Keypair

## Usage

```
Usage:
./provision.sh <# of segment hosts>

Environment Variables:

AWS_ACCESS_KEY            - AWS Access Key
AWS_SECRET_KEY            - AWS Secret Key
AWS_KEYPAIR               - AWS Keypair Name

AMI                       - Centos 6 HVM AMI (Default: ami-c2a818aa)
INSTANCE_TYPE             - EC2 Instance Type (Default: i2.8xlarge)

VPC_ID                    - VPC for subnet (Default: not set)
SUBNET_ID                 - Subnet for instances (Default: not set)

ETL_RATIO                 - Number of segment hosts per ETL host (Default: 4)
ETL_HOSTS                 - Number of ETL hosts (Default: # of segment hosts / $ETL_RATIO)

STANDBY                   - Number of standby master nodes, can be 0 or 1 (Default: 0)
```

## Note

All instances are provisioned into a subnet. If a `SUBNET_ID` is not provided, a new subnet will be created in the VPC specified by `VPC_ID`. If a `VPC_ID` is not provided, a new VPC with a public gateway and open security group will be created. 

When provisioning multiple clusters, you can reuse subnets by specifying a `SUBNET_ID`.
