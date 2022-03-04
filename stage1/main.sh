#!/usr/bin/env bash
# Stage 1
# ~~~~~~~
set -e

if [ "$UID" != "0" ]
then
    echo "ERROR: $0 must be run as root."
    exit -1
fi

if [ -z "$LFS" ]
then
    echo "ERROR: $0: Missing config vars."
    exit -1
fi

cd $(get_script_dir $BASH_SOURCE)

echo -n "Checking dependency versions... "
./check_dep_versions.sh
echo "done."

echo -n "Building image... "
./build_img.sh
echo "done."

