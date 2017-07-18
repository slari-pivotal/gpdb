#!/bin/bash
set -eufo pipefail

## ########################################################################
## Script to fix a MADlib installation issue on GPDB 4.3.10.
## ########################################################################

COMMAND=`basename $0`
USAGE="COMMAND NAME: ${COMMAND}

Script to fix a MADlib installation issue on GPDB 4.3.10.

This script patches a line in madpack.py, the MADlib installation
script. A backup of the original file is created in the same folder as
madpack.py called 'madpack.py.orig'.

*****************************************************
SYNOPSIS
*****************************************************

${COMMAND} [--prefix <MADLIB_INSTALL_PATH>]

${COMMAND} -h


*****************************************************
PREREQUISITES
*****************************************************

The following tasks should be performed prior to executing this script:

* Set GPHOME to the correct GPDB installation directory containing MADlib
OR
* Set MADlib installation path using the --prefix option


*****************************************************
OPTIONS
*****************************************************

--prefix <MADLIB_INSTALL_PATH>
 Optional. Expected MADlib installation path. If not set, the default value
 \${GPHOME}/madlib is used.

-h | -? | --help
 Displays the online help.


*****************************************************
EXAMPLE
*****************************************************

/home/gpadmin/madlib/${COMMAND} --prefix /usr/local/gpdb/madlib
"
HELP="Try option -h for detailed usage."

## ########################################################################
## parsing command-line args
if [ $# -gt 0 ]; then
    # if argument provided then
    case "$1" in
        --prefix)
            if [ $# -lt 2 ]; then
                echo "$0: MADLIB_INSTALL_PATH not provided. ${HELP}";
                exit 1;
            else
                MADLIB_INSTALL_PATH=$2;
            fi;;
        -h|-?|--help)
            echo "${USAGE}";
            exit 1;;
        *)
            echo "$0: No such option $1. ${HELP}";
            exit 1;;
    esac
else
        if [ -z ${GPHOME+x} ]; then
                echo "GPHOME is unset.";
        else
                MADLIB_INSTALL_PATH="$GPHOME/madlib";
        fi
fi

if [ -z ${MADLIB_INSTALL_PATH+x} ]; then
    echo "MADLIB_INSTALL_PATH is unset. ${HELP}";
else
    echo "Using MADlib installation path: ${MADLIB_INSTALL_PATH}"
fi

# replace text in every relevant file
BASE_DIR="$MADLIB_INSTALL_PATH/Current/madpack"
FILE="$BASE_DIR/madpack.py"

if [ -f $FILE -a -r $FILE ]; then
    # Patch options used:
    # -N: Ignore patches that seem to be reversed or already applied
    # -b: Create a backup file of the original
    patch -b -N "$FILE" <<-EOF
diff --git a/madpack.py b/madpack.py
index b8db427..8d31331 100755
--- a/madpack.py
+++ b/madpack.py
@@ -357,7 +357,7 @@ def _get_rev_num(rev):
         @param rev version text
     """
     try:
-        num = re.findall('[0-9]', rev)
+        num = tuple(int(i) for i in rev.split('.'))
         if num:
             return num
         else:

EOF
else
        echo "Error: Cannot read $FILE"
fi

if [ 0 -ne $? ]; then
    echo "$0: Cannot successfully update one or more files!"
    exit 1
else
    echo "Successfully patched necessary files"
fi
