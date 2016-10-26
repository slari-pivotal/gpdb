## Overview
This document describes the steps required to produce a release specific to Morgan Stanley(MS).

### Prerequisites

- Release branch has already been cut

### Steps
1. Increment the last release number by 1 for a new MS release.
2. Checkout a new branch for MS including the new release number.
	
	```
	$ git checkout -b <new_branch> <base_branch>
	$ git checkout -b 4.3.9.0MS27 4.3.9.0
	```
3. Update the release number in the below files. The artifacts name are hardcoded in the scripts as required by Concourse, so we need to update them with every release:
	* ci/concourse/pipelines/morgan-stanley-pipeline.yml
	* customer-patches/morgan-stanley/scripts/gen-customer-installer.sh
	* getversion

	Note: As of 08/17, the files listed above only requires the change. In case, there are new files added later which needs an update, please update them as well.
	You can use the below script to update the same.
	Ex:
	* Release Number from the base branch: 4.3.9.0.
	* Targeted Release Number for MS branch: 4.3.9.0MS27.

 	```
 	$for file in ci/concourse/pipelines/morgan-stanley-pipeline.yml customer-patches/morgan-stanley/scripts/gen-customer-installer.sh getversion ; do sed -i s/4.3.9.0/4.3.9.0MS27/g $file ; done
 	```

	The artifact names in Concourse are hardcoded because the way the pipeline is currently configured has directory structure in the same variable as the filename.
	In different parts of the pipeline, the directory structure for the local context is different (S3 bucket, mounted into a container volume, etc.)
	We attempted to refactor the pipelines to unblock this but ran into issues.
4. Create the pre-requisites as required by the pipeline
	* Create and check in a new credential file with updated parameter values (git branch and s3 bucket) in [gpdb-ci-deployments](https://www.github.com/greenplum-db/gpdb-ci-deployments)
	  + Create the credential file by copying from the corresponding release branch file. It will have many extraneous values, but should be the most up-to-date
		+ Add in the variable `noarch-toolchain-snowflakes-bucket`, most easily by copying from the previous Morgan Stanley release's credentials file. This configures where to get the Madlib gppkg from.
		+ Ask the Toolsmiths if the auto-push to FTP feature is enabled yet. If not, you'll have to upload it manually
	* Ensure that a new buckets are created to avoid overwriting the artifacts, and make the buckets "versioned"
5. Fly set a new pipeline, push the files to git and start it.
6. Should the morgan-stanley/README.md be updated with MD5's from the end of the build process?
7. Make sure it gets up to the FTP server and Morgan Stanley receives it

You should see the gpdb server and clients artifacts generated in `<main_bucket_name>/morganstanleydeliverables` packaged as required by MS after pipeline completion.
