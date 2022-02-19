#!/usr/bin/bash
# Script to create OS image file
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This script might be considered a little bit
# dangerous since it needs to be run as root,
# and involves partitioning, creating new filesystems,
# mounting, etc. I tried to make it somewhat safer
# by operating only image files that are mounted as
# loop devices. So ideally, it won't touch any actual
# block devices.

set -e # exit if any command fails
MYLFS_SIZE=$((10*1024*1024*1024)) # 10 GiB
MYLFS_IMG=mylfs.img
MYLFS=/mnt/mylfs
MYLFS_FS=ext4

if [ $UID != "0" ]
then
    echo "$0 must be executed as root"
    exit -1
fi

# create image file
echo "Creating disk image..."
fallocate -l$MYLFS_SIZE $MYLFS_IMG
echo "Done."

# attach loop device
LOOP=$(losetup -f)
echo "Creating loop device ${LOOP}..."
losetup $LOOP $MYLFS_IMG
echo "Done."

# partition the device
echo "Partitioning device..."
FDISK_STR="
g       # create GPT
n       # new partition
        # default 1st partition
        # default start sector (2048)
+512M   # 512 MiB
t       # modify parition type
1       # EFI type
n       # new partition
        # default 2nd partition
        # default start sector
        # default end sector
w       # write to device and quit
"
FDISK_STR=$(echo "$FDISK_STR" | sed 's/ *#.*//g')
# fdisk fails to get kernel to re-read the partition table
# so ignore non-zero exit code, and manually re-read
set +e
fdisk $LOOP >> /dev/null <<EOF
$FDISK_STR
EOF
set -e
echo "Done."

# reattach loop device to re-read partition table
echo "Reattaching loop device $LOOP..."
losetup -d $LOOP
sleep 1 # give the kernel a sec
losetup -P $LOOP $MYLFS_IMG
echo "Done."

# create filesystem
echo "Creating $MYLFS_FS filesystem..."
LOOP_P2="${LOOP}p2"
mkfs -t $MYLFS_FS $LOOP_P2 >> /dev/null

# mount root partition
echo "Mounting root partition to $MYLFS"
if [ ! -d $MYLFS ]
then
    mkdir $MYLFS
fi
mount $LOOP_P2 $MYLFS
echo "Done."
