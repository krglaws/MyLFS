#!/usr/bin/env bash
# Script to create OS image file
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set -e

# create image file
fallocate -l$LFS_IMG_SIZE $LFS_IMG

# attach loop device
LOOP=$(losetup -f)
losetup $LOOP $LFS_IMG

# partition the device
FDISK_STR="
g       # create GPT
n       # new partition
        # default 1st partition
        # default start sector (2048)
+512M   # 512 MiB
t       # modify parition type
uefi    # EFI type
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

# reattach loop device to re-read partition table
losetup -d $LOOP
sleep 1 # give the kernel a sec
losetup -P $LOOP $LFS_IMG

# label the partitions
LOOP_P1=${LOOP}p1
LOOP_P2=${LOOP}p2
dosfslabel $LOOP_P1 $LFSEFILABEL
e2label $LOOP_P2 $LFSROOTLABEL

# setup root partition
mkfs -t $LFS_FS $LOOP_P2 &>> /dev/null
mkdir -p $LFS
mount $LOOP_P2 $LFS

# setup EFI partition
mkfs.vfat $LOOP_P1
mkdir -p $LFS/boot/efi
mount -t vfat $LOOP_P1 $LFS/boot/efi

