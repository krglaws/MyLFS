#!/usr/bin/env bash
# Script to create OS image file
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set -e

# create image file
echo -n "Creating disk image... "
fallocate -l$LFS_IMG_SIZE $LFS_IMG
echo "done."

# attach loop device
LOOP=$(losetup -f)
echo -n "Creating loop device ${LOOP}... "
losetup $LOOP $LFS_IMG
echo "done."

# partition the device
echo -n "Partitioning device... "
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
fdisk $LOOP &>> /dev/null <<EOF
$FDISK_STR
EOF
set -e
echo "done."

# reattach loop device to re-read partition table
echo -n "Reattaching loop device $LOOP... "
losetup -d $LOOP
sleep 1 # give the kernel a sec
losetup -P $LOOP $LFS_IMG
echo "done."

# create filesystem
echo -n "Creating $LFS_FS filesystem... "
LOOP_P2="${LOOP}p2"
mkfs -t $LFS_FS $LOOP_P2 &>> /dev/null
echo "done."

# mount root partition
echo -n "Mounting root partition to ${LFS}..."
if [ ! -d $LFS ]
then
    mkdir $LFS
fi
mount $LOOP_P2 $LFS
echo "done."

