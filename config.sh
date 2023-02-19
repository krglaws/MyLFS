# #######################
# LFS Build Configuration
# ~~~~~~~~~~~~~~~~~~~~~~~

FULLPATH=$(cd $(dirname $0) && pwd)

export LFS_VERSION=11.2
export KERNELVERS=5.19.2
export PACKAGE_LIST=$FULLPATH/packages.sh
export PACKAGE_DIR=$FULLPATH/packages
export LOG_DIR=$FULLPATH/logs
export KEEP_LOGS=true
export LFS=$FULLPATH/mnt/lfs
export INSTALL_MOUNT=$FULLPATH/mnt/install
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export LFS_FS=ext4
export LFS_IMG=$FULLPATH/lfs.img
export LFS_IMG_SIZE=$((10*1024*1024*1024)) # 10 GiB
export TESTLOG_DIR=$FULLPATH/testlogs
export LFSROOTLABEL=LFSROOT
export LFSEFILABEL=LFSEFI
export LFSFSTYPE=ext4

# configure these like `MAKEFLAGS=-j1 RUN_TESTS=true ./mylfs.sh --build-all`
export MAKEFLAGS=${MAKEFLAGS:--j8}
export RUN_TESTS=${RUN_TESTS:-false}
export ROOT_PASSWD=${ROOT_PASSWD:-password}
export LFSHOSTNAME=${LFSHOSTNAME:-lfs}

export FDISK_INSTR="
o       # create DOS partition table
n       # new partition
        # default partition type (primary)
        # default partition number (1)
        # default partition start
        # default partition end (max)
y       # confirm overwrite (noop if not prompted)
w       # write to device and quit
"

KEYS="MAKEFLAGS PACKAGE_LIST PACKAGE_DIR LOG_DIR KEEP_LOGS LFS LFS_TGT"\
" LFS_FS LFS_IMG LFS_IMG_SIZE ROOT_PASSWD RUN_TESTS TESTLOG_DIR LFSHOSTNAME"\
" LFSROOTLABEL LFSEFILABEL LFSFSTYPE KERNELVERS FDISK_INSTR"

for KEY in $KEYS
do
    if [ -z "${!KEY}" ]
    then
        echo "ERROR: '$KEY' config is not set."
        exit -1
    fi
done

