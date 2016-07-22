# Greenplum Database on Amazon Web Services

## Description

This toolkit automates the creation and benchmark of a Greenplum Database cluster on Amazon Web Services. 

| Tool | Description |
| --- | --- |
| [provision](./provision) |  Provisions EC2 instances in preparation for GPDB installation |
| [prepare](./prepare) | Configures software packages, kernel parameters, security settings and storage in preparation for GPDB installation |
| [install](./install) | Installs GPDB onto a set of provisioned and prepared EC2 instances |
| [benchmark](./benchmark) | Benchmark load and query performance |

## Prerequisites

* OS X or Linux machine
* [EC2 Tools](http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/set-up-ec2-cli-linux.html)
* Amazon Web Services account
* Pivotal Greenplum Database [installation files](https://network.pivotal.io/products/pivotal-gpdb):
  * Greenplum Data Computing Appliance Database Installer
  * Greenplum Command Center
  * Greenplum Loaders

### AWS Service Limits

The following service limit increases are required:

| Resource         | Limit           |
| ---              | ---             |
| i2.8xlarge limit | Size of cluster |
| VPC              | 1 per cluster   |
| Security group   | 1 per cluster   |

### Required Environment Variables

The following environment variables are required:

| Name              | Value                                                              |
| ---               | ---                                                                |
| AWS_ACCESS_KEY    | Access Key provided by Amazon necessary to use the EC2 API Tools   |
| AWS_SECRET_KEY    | Secret Token provided by Amazon necessary to use the EC2 API Tools |
| AWS_KEYPAIR       | Path to the keypair file used to log into the EC2 instances        |
| GREENPLUM_DB      | Path to the Greenplum Appliance Installer .bin file from PivNet    |
| GREENPLUM_CC      | Path to the Greenplum Command Center .zip file from PivNet         |
| GREENPLUM_LOADERS | Path to the Greenplum Loaders .zip file from PivNet                |

## Usage

```
Usage: ./setup.sh <number of segment hosts>

Environment Variables:

AWS_ACCESS_KEY            - AWS Access Key
AWS_SECRET_KEY            - AWS Secret Key
AWS_KEYPAIR               - AWS Keypair Path

GREENPLUM_DB              - Path to Greenplum Data Computing Appliance Database Installer bin file
GREENPLUM_LOADERS         - Path to Greenplum Database Loaders (RHEL x86_64) zip file
GREENPLUM_CC              - Path to Greenplum Command Center (RHEL x86_64) zip file
```

## Deploying a Cluster

1. Download the latest package from the [releases](https://github.com/Pivotal-DataFabric/gpdb-aws/releases) page and extract it.

1. Run the `setup` script with the desired number of segment hosts.

  ```$ ./setup.sh 4```

1. Confirm the cluster health by visiting the Greenplum Command Center at `http://<MASTER IP>:28080`.


## Deploying a Single-Node Cluster for Development

1. Download the latest package from the [releases](https://github.com/Pivotal-DataFabric/gpdb-aws/releases) page and extract it.

1. Run the `setup` script with zero segment hosts.

  ```$ ./setup.sh 0```

1. Confirm the cluster health by visiting the Greenplum Command Center at `http://<MASTER IP>:28080`.

## Deploying a Dual Cluster

1. Download the latest package from the [releases](https://github.com/Pivotal-DataFabric/gpdb-aws/releases) page and extract it.

1. Run the `setup` script with the STANDBY environment variable set to
   "1" and zero segment hosts.

  ```$ STANDBY=1 ./setup.sh 0```

## Running Benchmarks

1. Download the latest package from the [releases](https://github.com/Pivotal-DataFabric/gpdb-aws/releases) page and extract it.

1. Set up a cluster by following the [Deploying a Cluster](#deploying-a-cluster) list above.

1. Note the path to the external hostfile.

1. *(Optional)* Set the `SCALE` environment variable to the number of gigabytes of data to generate. Default is `1`.

1. Run the `benchmark` script with the IP address of the `etl` node.

  ```$ ./benchmark/benchmark.sh </path/to/external-hostfile>```

1. Read the report in the directory specified by the output of the `benchmark` script.
