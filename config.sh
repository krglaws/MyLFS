# #######################
# LFS Build Configuration
# ~~~~~~~~~~~~~~~~~~~~~~~

FULLPATH=$(cd $(dirname $0) && pwd)

export MAKEFLAGS=-j8
export PACKAGE_LIST=$FULLPATH/pkgs.sh
export PACKAGE_DIR=$FULLPATH/pkgs
export LOG_DIR=$FULLPATH/logs
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export LFS_FS=ext4
export LFS_IMG=$FULLPATH/lfs.img
export LFS_IMG_SIZE=$((10*1024*1024*1024)) # 10 GiB
export ROOT_PASSWD=password
export RUN_TESTS=false
export BUILDLOG_DIR=$FULLPATH/buildlogs
export TESTLOG_DIR=$FULLPATH/testlogs
export LFSHOSTNAME=lfs
export LFSROOTLABEL=LFSROOT
export LFSEFILABEL=LFSEFI
export LFSFSTYPE=ext4

KEYS="MAKEFLAGS PACKAGE_LIST PACKAGE_DIR LOG_DIR"\
" LFS LFS_TGT LFS_FS LFS_IMG LFS_IMG_SIZE ROOT_PASSWD RUN_TESTS TESTLOG_DIR"\
" LFSHOSTNAME LFSROOTLABEL LFSEFILABEL LFSFSTYPE"

for KEY in $KEYS
do
    if [ -z ${!KEY} ]
    then
        echo "ERROR: '$KEY' config is not set."
        exit -1
    fi
done

