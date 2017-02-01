## Release checklist

1. Release branch has already been cut
2. Identify new release version by using MS suffix +1
3. git fetch
4. git checkout -b release-4.3.11.3MS32 origin/release-4.3.11.3
5. replace version in ci/concourse/pipelines/morgan-stanley-pipeline.yml
6. replace version in customer-patches/morgan-stanley/scripts/gen-customer-installer.sh
7. replace version in getversion
8. create bucket in s3 by copying format of bucket from last release
9. enable versioning on the bucket
10. switch repos and git pull latest code: gpdb-ci-deployments
11. copy the credential file from last release to a new name for this release from this location: ` $ cp gpdb-4.3.11.3-ci-secrets.yml gpdb-4.3.11.3MS32-ci-secrets.yml`
12. Add in this line to the bottom of the new secrets file `noarch-toolchain-snowflakes-bucket: noarch-toolchain-snowflakes`
13. edit the `gpdb-git-branch` and `bucket-name` fields in the secrets file
13. commit and push secrets file
14. switch back to the gpdb4 repo
15. Log in to Concourse from the command line: `fly -t shared login -c https://shared.ci.eng.pivotal.io -n GPDB`
16. Fly set a new pipeline: `fly -t shared set-pipeline -p 4.3.11.3MS32 -c ci/concourse/pipelines/morgan-stanley-pipeline.yml -l ../gpdb-ci-deployments/gpdb-4.3.11.3MS32-ci-secrets.yml`
17. `git push` to the Morgan Stanley branch in the `gpdb4` repository
18. Unpause the pipeline: `fly -t shared unpause-pipeline -p 4.3.9.0MS27`
19. Kick off the bootstrap job: `fly -t shared trigger-job -j 4.3.11.3MS32/bootstrap-ccache`
