#!/usr/bin/bash
# Cleans up the mounted image file
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set -e

if [ "$UID" != "0" ]
then
    echo "ERROR: $0 must be run as root."
    exit -1
fi

cd $(dirname $0)
source ./config.sh

# unmount $LFS
if [ -n "$(mount | grep $LFS)" ]
then
    echo "Unmounting ${LFS}..."
    mount | grep $LFS | cut -d" " -f3 | tac | xargs umount
fi

# detach loop device
if [ -n "$(losetup | grep $LFS_IMG)" ]
then
    echo "Detaching ${LFS_IMG}..."
    losetup -d $(echo "$(losetup | grep $LFS_IMG)" | cut -d" " -f1)
fi

# delete img
if [ -f $LFS_IMG ]
then
    read -p "WARNING: This will delete ${LFS_IMG}. Continue? (Y/N): " CONFIRM
    [[ $CONFIRM == [yY] || $CONFIRM == [yY][eE][sS] ]] || { echo "Cancelled." && exit -1; }
    echo "Deleting ${LFS_IMG}..."
    rm $LFS_IMG
fi

# delete logs
if [ -n "$(ls ./logs)" ]
then
    rm -rf ./logs/*log ./logs/*gz
fi

