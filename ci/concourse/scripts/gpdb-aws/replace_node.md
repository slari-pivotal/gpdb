# Replace a Failed Node

## Setup a new machine ##
* Run the setup script to provision a new machine with GPDB & GPCC installed on it.
	
	```
	$ ./setup.sh 0
	```

## Replace the old machine ##
* Copy over ssh keys from the old machine to the new machine.
	
	```
	$ mkdir ssh_folder
	$ scp -i <aws_keypair> root@old.machine.ip:/root/.ssh/* ssh_folder/
	$ scp -i <aws_keypair> ssh_folder/* root@new.machine.ip:/root/.ssh/
	$ scp -i <aws_keypair> ssh_folder/* root@new.machine.ip:/home/gpadmin/.ssh/
	```

* Ssh into the new machine.
	
	```
	$ ssh -i <aws_keypair> root@new.machine.ip
	```
	
* Update `~/.ssh/authorized_keys` & `known_hosts` as `root` & `gpadmin` so the old machines can connect to the new machine.

	```	
	# scp old.machine.ip:/home/gpadmin/.ssh/authorized_keys /home/gpadmin/.ssh/authorized_keys
	# scp old.machine.ip:/home/gpadmin/.ssh/known_hosts /home/gpadmin/.ssh/known_hosts
	# chown -R gpadmin:gpadmin /home/gpadmin/.ssh/*
	```
	
* Login as the gpadmin user `su - gpadmin`.
* Run `gpdeletesystem` to delete the GPDB installation.
* Shutdown the old machine you want to replace. This ensures that the segments get marked as down so they can be migrated with `gprecoverseg`.

* Update the hosts file on the new machine, make sure that records for `mdw` and `smdw` are appropriate.

## Recover the cluster ##

* `gprecoverseg -p <new machine>` to push the failed segments to the new machine

* If replacing the master
  * `gpactivatestandby` on the standby to turn it to the master
  * `gpactivatestandby -s <new machine>` to turn the new machine into the new standby
* If replacing the standby master
  * `gpactivatestandby -r <old standby>` to remove the current standby & `gpactivatestandby -s <new standby>` to activate the new standby
  
* Rebalance mirrors and standbys using `gprecoverseg -r`

* Check `gpstate -e` and `gpstate` to make sure that the rebalance succeeded and the new standby is appropriate
