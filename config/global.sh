# LFS Build Configuration
# ~~~~~~~~~~~~~~~~~~~~~~~
# This file should be sourced by the other scripts
# that need these variables.

export CONF_DIR=$(cd $(dirname $BASH_SOURCE) && pwd)
export MAIN_DIR=$(dirname $CONF_DIR)
export GLOBAL_CONF=$CONF_DIR/global.sh
export USER_CONF=$CONF_DIR/user.sh
export MAKEFLAGS=-j4
export PACKAGE_LIST=$CONF_DIR/pkgs.sh
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export LFS_FS=ext4
export LFS_IMG=$MAIN_DIR/lfs.img
export LFS_IMG_SIZE=$((10*1024*1024*1024)) # 10 GiB
export LFS_USER=lfs
export ROOT_PASSWD=password
export RUN_TESTS=false
export TESTLOG_DIR=/sources/tests
export HOSTNAME=lfs
export LFSROOTLABEL=lfsroot
export LFSEFILABEL=lfsefi
export LFSFSTYPE=ext4

KEYS="CONF_DIR MAIN_DIR GLOBAL_CONF USER_CONF MAKEFLAGS PACKAGE_LIST"\
" LFS LFS_TGT LFS_FS LFS_IMG LFS_IMG_SIZE LFS_USER ROOT_PASSWD RUN_TESTS TESTLOG_DIR"\
" HOSTNAME LFSROOTLABEL LFSEFILABEL LFSFSTYPE"

for KEY in $KEYS
do
    if [ -z ${!KEY} ]
    then
        echo "ERROR: '$KEY' config is not set."
        exit -1
    fi
done

