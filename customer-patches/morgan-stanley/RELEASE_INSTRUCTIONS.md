## Overview
This document describes the steps required to produce a release specific to Morgan Stanley(MS).

### Steps
1. Increment the last release number by 1 for a new MS release.
2. Checkout a new branch for MS including the new release number.
	
	```
	$ git checkout -b <new_branch> <base_branch>
	$ git checkout -b 4.3.9.0MS27 4.3.9.0	
	```
3. Update the release number in the below files:
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
4. Create the buckets as required by the pipeline
5. Push the files to git, fly set a new pipeline and start it.

You should see the gpdb server and clients artifacts generated in <main_bucket_name>/morganstanleydeliverables packaged as required by MS after pipeline completion.
