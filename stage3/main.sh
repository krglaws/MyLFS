#!/usr/bin/env bash
# Stage 3
# ~~~~~~~
set -e

if [ -z "$LFS" -o -z "$LFS_USER" ]
then
    echo "ERROR: Missing config vars. Be sure to source config.sh before running this script."
    exit -1
fi

if [ "$LFS_USER" != "$USER" ]
then
    echo "This script needs to be run as $LFS_USER."
    exit -1
fi

function build_package {
    PACKAGE_NAME=$1
    BUILD_SCRIPT=$2
    BUILD_LOG=$3

    echo -n "Building ${PACKAGE_NAME}... "
    if ! { $BUILD_SCRIPT &> $BUILD_LOG && rm $BUILD_LOG && echo "done."; }
    then
        echo "failed. Check $BUILD_LOG for more information."
        exit -1
    fi
}

SCRIPT_DIR=$(get_script_dir $BASH_SOURCE)

build_package "Binutils pass 1" $SCRIPT_DIR/binutils.sh $LFS/sources/binutils_pass1.log
build_package "GCC pass 1" $SCRIPT_DIR/gcc.sh $LFS/sources/gcc_pass1.log
build_package "Linux headers" $SCRIPT_DIR/linux_headers.sh $LFS/sources/linux_headers.log
build_package "Glibc pass1" $SCRIPT_DIR/glibc.sh $LFS/sources/glibc_pass1.log
build_package "libstdcpp" $SCRIPT_DIR/libstdcpp.sh $LFS/sources/libstdcpp.log

