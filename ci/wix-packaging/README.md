## The wix-packaging VM for producing Windows CCLs

wix-packaging.ci.eng.pivotal.io

This directory describes how to configure a Windows machine to package the CCLs for that platform.
It has a Cloudformation template for launching an AWS instance from an AMI which is ready to package
the CCLs with Wix. See the toolsmiths-images repository for more information on the AMI.
Unfortunately, as of Dec. 2016, the process for generating the AMI is manual, based on a README.md

The particular AMI that this Cloudformation expects to use is encoded in the Cloudformation template.

`aws cloudformation update-stack --stack-name wix-packaging --template-body "$(cat cloudformation-template.yml)"`

Wix is a native windows tool for creating self-contained installer files.

The gpAux/client makefiles collapse Windows CCL compilation and packaging together into one step.
As such, the way to get compilation to work with the makefiles as currently written (as of 11/17/2016)
is to stand up a windows server separately, which responds to SSH at port 22 (typically using cygwin),
and has Wix installed, ready to run.

Once a server is up and running, the compilation steps would work with it over SSH, but an operator
could use RDP to log in.
