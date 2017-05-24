#!/bin/bash

source $HOME/qa.sh

cd $BLDWRAP_TOP/src/gpMgmt

make -f Makefile.behave behave "$*" TAR=tar 2>&1
