# Backup to S3

* Log into the master host

	```
	$ ssh -i <aws_keypair> root@master.ip
	```
	

* Create a backup folder to back up the data on the master and create the same folder on all segment hosts in the cluster

	```
	# mkdir -p /data1/backup
	# HOSTS=(sdw1 sdw2 sdwN)
	# for host in ${HOSTS[@]}; do ssh $host "mkdir -p /data1/backup && chown -R gpadmin:gpadmin /data1/backup"; done
	```

* Install the `awscli`	tool

	```
	# yum install epel-release
	# yum install python-pip
	# pip install awscli
	```
	Ensure the `gpadmin` user can run the `aws` tool
	
	```
	$ gpssh echo 'alias aws="PYTHONHOME=/usr PYTHONPATH=/usr/lib64/python2.6/ LD_LIBRARY_PATH= /usr/bin/aws"' >> ~/.bashrc
	```

* Login as the gpadmin user

	```
	# su - gpadmin
	```

* Run the `gpcrondump` utility to backup the DB.
 
	```
	$ gpcrondump -x <DATABASE NAME> -a -b -g -G -u /data1/backup
	```

	This would backup the DB to the `/data1/backup` directory. The supplied flags are explained below:
	
	* **-a** (Do not prompt the user for confirmation.)
	* **-b** (Bypass disk space check.)
	* **-g** (Backup the config files of the master and segment configuration files *__postgresql.conf__*, *__pg_ident.conf__*, and *__pg_hba.conf__*.)
	* **-G** (Dump global objects such as roles and tablespaces.)
	* **-u** (Specify the absolute path where the backup files will be placed on each host.)
	
	-


* Use the `awscli` tool to upload the backup data to AWS S3

 	```
 	$ gpssh -h sdw1 -h sdw2 -h sdwN -e "cd /data1/backup && find . -name '*gp_*' | sed -e 's,^\./,,' | xargs -n1 -P10  -I {} aws s3 cp ./{} s3://<bucket-name>/backups/\$(hostname)/<path>/{}"
	```
	This will upload all the backup files on all the segments to the S3 bucket specified.
	`xargs` is used with the flag `-P10` so we can run aws tool in 10 parallel processes to parallelize the uploads and upload the data faster to S3.
	
	Also `$(hostname)` is added to the backup path on S3 so we can easily pull down the data back to the right segment host during the restore process.	

