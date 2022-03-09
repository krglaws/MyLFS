#!/usr/bin/env bash
# Stage 1
# ~~~~~~~
# This stage covers chapters 1-2 of LFS 11.1,
# which involves checking system requirements,
# and creating and partitioning a virtual disk.
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

cd $(dirname $0)

echo -n "Checking dependency versions... "
./check_dep_versions.sh
echo "done."

echo -n "Building image... "
./build_img.sh
echo "done."

