#!/usr/bin/bash
# Cleans up the mounted image file
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set -e
source ./config.sh

echo "Cleaning LFS image..."

# unmount $LFS
if [ -n "$(mount | grep $LFS)" ]
then
    echo "Unmounting ${LFS}..."
    umount $LFS
    echo "Done."
fi

# detach loop device
if [ -n "$(losetup | grep $LFS_IMG)" ]
then
    echo "Detaching ${LFS_IMG}..."
    losetup -d $(echo "$(losetup | grep $LFS_IMG)" | cut -d" " -f1)
    echo "Done."
fi

# delete img
if [ -f $LFS_IMG ]
then
    echo "Deleting ${LFS_IMG}..."
    rm $LFS_IMG
    echo "Done."
fi

echo "Done."
