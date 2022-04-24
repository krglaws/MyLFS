# #######################
# LFS Build Configuration
# ~~~~~~~~~~~~~~~~~~~~~~~

FULLPATH=$(cd $(dirname $0) && pwd)

export MAKEFLAGS=-j8
export PACKAGE_LIST=$FULLPATH/pkgs.sh
export PACKAGE_DIR=$FULLPATH/pkgs
export LOG_DIR=$FULLPATH/logs
export KEEP_LOGS=false
export LFS=$FULLPATH/mnt/lfs
export INSTALL_MOUNT=$FULLPATH/mnt/install
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export LFS_FS=ext4
export LFS_IMG=$FULLPATH/lfs.img
export LFS_IMG_SIZE=$((10*1024*1024*1024)) # 10 GiB
export ROOT_PASSWD=password
export RUN_TESTS=false
export TESTLOG_DIR=$FULLPATH/testlogs
export LFSHOSTNAME=lfs
export LFSROOTLABEL=LFSROOT
export LFSEFILABEL=LFSEFI
export LFSFSTYPE=ext4
export KERNELVERS=5.16.9

export FDISK_INSTR_BIOS="
o       # create DOS partition table
n       # new partition
        # default partition type (primary)
        # default partition number (1)
        # default partition start
        # default partition end (max)
y       # confirm overwrite (noop if not prompted)
w       # write to device and quit
"

export FDISK_INSTR_UEFI="
g       # create GPT
n       # new partition
        # default 1st partition
        # default start sector (2048)
+512M   # 512 MiB
y       # confirm overwrite (noop if not prompted)
t       # modify parition type
1       # EFI type
n       # new partition
        # default 2nd partition
        # default start sector
        # default end sector
y       # confirm overwrite (noop if not prompted)
w       # write to device and quit
"

KEYS="MAKEFLAGS PACKAGE_LIST PACKAGE_DIR LOG_DIR KEEP_LOGS LFS LFS_TGT"\
" LFS_FS LFS_IMG LFS_IMG_SIZE ROOT_PASSWD RUN_TESTS TESTLOG_DIR LFSHOSTNAME"\
" LFSROOTLABEL LFSEFILABEL LFSFSTYPE KERNELVERS FDISK_INSTR_BIOS FDISK_INSTR_UEFI"

for KEY in $KEYS
do
    if [ -z "${!KEY}" ]
    then
        echo "ERROR: '$KEY' config is not set."
        exit -1
    fi
done

