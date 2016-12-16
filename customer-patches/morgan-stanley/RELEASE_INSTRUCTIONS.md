## Overview
This document describes the steps required to produce a release specific to Morgan Stanley(MS).

### Prerequisites

- Release branch has already been cut

### Steps
1. Increment the last release number by 1 for a new MS release.
1. Checkout a new branch for MS including the new release number.

	```
	$ git fetch
	$ #git checkout -b <new_branch> origin/<base_branch>
	$ git checkout -b 4.3.9.0MS27 origin/4.3.9.0 
	```
1. Update the release number in the below files. The artifacts name are hardcoded in the scripts as required by Concourse, so we need to update them with every release:
	* ci/concourse/pipelines/morgan-stanley-pipeline.yml
	* customer-patches/morgan-stanley/scripts/gen-customer-installer.sh
	* getversion

	Note: getversion is updated from current GPDB version, and MS scripts are updated from last MS release number on 4.3_STABLE

	The artifact names in Concourse are hardcoded because the way the pipeline is currently configured has directory structure in the same variable as the filename.
	In different parts of the pipeline, the directory structure for the local context is different (S3 bucket, mounted into a container volume, etc.)
	We attempted to refactor the pipelines to unblock this but ran into issues.
1. Create the pre-requisites as required by the pipeline
   * Ensure that a new bucket is created to avoid overwriting the artifacts, and enable AWS S3 "versioning" on the bucket
   * Create the credential file by copying from the corresponding release branch file in [gpdb-ci-deployments](https://www.github.com/greenplum-db/gpdb-ci-deployments). It will have many extraneous values, but should be the most up-to-date starting point ` $ cp gpdb-4.3.9.0-ci-secrets.yml gpdb-4.3.9.0MS27-ci-secrets.yml`
   * Add in this line to the bottom of the file `noarch-toolchain-snowflakes-bucket: noarch-toolchain-snowflakes`.  This configures where to get the Madlib gppkg from.
   * Change the `gpdb-git-branch` and `bucket-name` fields in the credentials file
   * Check in the new credential file
1. Download `fly` (if necessary)
1. Log in to Concourse from the command line: `fly -t shared login -c https://shared.ci.eng.pivotal.io -n GPDB`
1. Fly set a new pipeline: `fly -t shared set-pipeline -p 4.3.9.0MS27 -c ci/concourse/pipelines/morgan-stanley-pipeline.yml -l ../gpdb-ci-deployments/gpdb-4.3.9.0MS27-ci-secrets.yml`
1. `git push` to the Morgan Stanley branch in the `gpdb4` repository
1. Unpause the pipeline: `fly -t shared unpause-pipeline -p 4.3.9.0MS27`
1. Watch it run.
1. Find the packages. You should see the gpdb server and clients artifacts
	 generated in S3 at `<main_bucket_name>/deliverables` packaged
	 as required by MS after pipeline completion.
1. Make sure it gets up to the FTP server and Morgan Stanley receives it
     + Ask the Toolsmiths if the auto-push to FTP feature is enabled yet. If not, you'll have to upload it manually

#### Finding the packages

The toolsmiths are looking to automate how we push to FTP:
[story for automating FTP](https://www.pivotaltracker.com/story/show/128436597)
Until then...

1. From the concourse pipeline, observe the 4 output resources at the end of
	 the pipeline (thin black rectangles between
	 "apply_morgan_stanley_specific_patches" and "gpdb_sync_to_dist")
2. Clicking into each, you'll see one version ID. Click on the version_id to
	 reveal the metadata for that artifact
3. Going to the URL should give you an error, but reading the XML will reveal
	 where to find these.
4. Two options

Option "CLI":

- Install the `awscli` with `pip install awscli`
- `aws configure` and log in with your Access Key ID and Secret Access Key,
	which you would create for your pivotal-pa-toolsmiths AWS account IAM user
- For each artifact, send a command like
  `aws s3 cp s3://bucket-name/directory-prefix/filename .`; in a recent case:
    + bucket-name is gpdb-4.3.10.0ms29-concourse
    + directory-prefix is morganstanleydeliverables
    + filename is shown in the Concourse UI under metadata for a particular
		  resource version
- This works because you'll get the latest version. If you needed to get a
	version which was not the latest...	[We'll have to research that answer
	more.](https://www.pivotaltracker.com/story/show/133540511)

Option "GUI":

- Go to the pivotal-pa-toolsmiths AWS account with your IAM user
- In S3, go to the gpdb-4.3.10.0ms29-concourse bucket,
	morganstanleydeliverables directory prefix
- [Or just go straight to the directory prefix]
  (https://console.aws.amazon.com/s3/home?region=us-west-2#&bucket=gpdb-4.3.10.0ms29-concourse&prefix=morganstanleydeliverables/)
- Right click to download
- ALERT: don't go to "deliverables". [Story in Toolsmiths backlog to clarify
	the naming.](https://www.pivotaltracker.com/story/show/133541875)
