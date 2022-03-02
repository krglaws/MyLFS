#!/usr/bin/env bash
# Stage 1
# ~~~~~~~
set -e

if [ "$UID" != "0" ]
then
    echo "ERROR: $0 must be executed as root"
    exit -1
fi

if [ -z "$LFS" -o -z "$LFS_USER" ]
then
    echo "ERROR: Missing config vars. Be sure to source config.sh before running this script."
    exit -1
fi

SCRIPT_DIR=$(get_script_dir $BASH_SOURCE)

echo "Checking dependency versions..."
$SCRIPT_DIR/check_dep_versions.sh
echo "Finished checking dependencies."

echo "Building image..."
$SCRIPT_DIR/build_img.sh
echo "Finished building image."

