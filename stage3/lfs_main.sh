#!/usr/bin/env bash
# Stage 3 entry point for LFS user.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set -e

if [ -z "$LFS" -o -z "$LFS_USER" ]
then
    echo "ERROR: Missing config vars. Be sure to source config.sh before running this script."
    exit -1
fi

if [ "$LFS_USER" != "$USER" ]
then
    echo "$0 needs to be run as $LFS_USER."
    exit -1
fi

build_package "Binutils" ./binutils.sh $LFS/sources/binutils_stage3.log
build_package "GCC" ./gcc.sh $LFS/sources/gcc_stage3.log
build_package "Linux headers" ./linux_headers.sh $LFS/sources/linux_headers_stage3.log
build_package "Glibc" ./glibc.sh $LFS/sources/glibc_stage3.log
build_package "libstdcpp" ./libstdcpp.sh $LFS/sources/libstdcpp_stage3.log

