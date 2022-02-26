#!/usr/bin/bash
set -e

if [ $UID != "0" ]
then
    echo "$0 must be executed as root"
    exit -1
fi

if [ -z "$LFS_USR" ]
then
    echo "LFS_USR var not set. Be sure to source config.sh before running this script."
    exit -1
fi

if [ -z "$(getent group $LFS_USR)" ]
then
    echo "Creating group ${LFS_USER}..."
    groupadd $LFS_USER
    echo "Done."
fi

if ! id $LFS_USER
then
    echo "Creating user ${LFS_USER}..."
    useradd -s /bin/bash -g $LFS_USER -m -k /dev/null $LFS_USER
    echo "Done."
fi

echo "Checking dependency versions..."
./check_dep_versions.sh
echo "Done."

echo "Building image..."
./build_img.sh
echo "Done."

