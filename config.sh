#!/usr/bin/bash
# LFS Build Configuration
# ~~~~~~~~~~~~~~~~~~~~~~~
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export LFS_FS=ext4
export LFS_IMG=lfs.img
export LFS_IMG_SIZE=$((10*1024*1024*1024)) # 10 GiB
export LFS_USER=lfs


KEYS="LFS LFS_TGT LFS_FS LFS_IMG LFS_IMG_SIZE LFS_USER"

for KEY in $KEYS
do
    if [ -z ${!KEY} ]
    then
        echo "ERROR: '$KEY' config is not set."
        exit -1
    fi
done

