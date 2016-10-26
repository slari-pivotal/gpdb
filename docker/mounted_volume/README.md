# How to create a docker container for gpdb4 development with a synchronized, mounted directory for shared source between macOS and docker's centos

## NOTE: this is destructive, destroying any container that already exists with the name you choose. 
## NOTE: this script assumes that any existing container, running on the ports set in your gpdb4 source, has been turned off

Docker uses the same ports on a host.
 
 
## Steps
 
* download beta docker app for macOS if not already installed.
* run that docker macOS app; you should see the container whale icon in upper right corner on your mac.
* log into docker:

```bash
docker login
```

* clone gpdb4 and go to the docker/mounted_volume directory

```bash
cd ~/workspace/
git clone git@github.com:greenplum-db/gpdb4.git
cd docker/mounted_volume
```

* run the script that will set up your docker

```bash
./00_docker_gpdb4_setup.sh <your container name>
```

* after docker is set up, you can stop/start/attach at any time:

```bash
docker attach <your container name>
docker stop <your container name>
docker start <your container name>
```

NOTE: docker for macOS is buggy! whenever you have issues, one of the first things to try is to:
 
* quit the macOS docker app, 
* make sure it is dead (killall docker), 
* restart that docker macOS app 