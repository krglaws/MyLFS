#!/usr/bin/bash
# Cleans up the mounted image file
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set -e

if [ "$UID" != "0" ]
then
    echo "ERROR: $0 must be run as root."
    exit -1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source $SCRIPT_DIR/config/global.sh

echo "Cleaning LFS image..."

# unmount $LFS
if [ -n "$(mount | grep $LFS)" ]
then
    echo "Unmounting ${LFS}..."
    umount $LFS
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
    [[ $CONFIRM == [yY] || $CONFIRM == [yY][eE][sS] ]] || exit
    echo "Deleting ${LFS_IMG}..."
    rm $LFS_IMG
fi

echo "Done."

