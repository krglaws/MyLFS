#!/usr/bin/env bash
# Stage 4
# ~~~~~~~
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

build_package "M4" ./m4.sh $LFS/sources/m4_stage4.log
build_package "ncurses" ./ncurses.sh $LFS/sources/ncurses_stage4.log
build_package "Bash" ./bash.sh $LFS/sources/bash_stage4.log
build_package "Coreutils" ./coreutils.sh $LFS/sources/coreutils_stage4.log
build_package "Diffutils" ./diffutils.sh $LFS/sources/diffutils_stage4.log
build_package "File" ./file.sh $LFS/sources/file_stage4.log
build_package "Findutils" ./findutils.sh $LFS/sources/findutils_stage4.log
build_package "Gawk" ./gawk.sh $LFS/sources/gawk_stage4.log
build_package "Grep" ./grep.sh $LFS/sources/grep_stage4.log
build_package "Gzip" ./gzip.sh $LFS/sources/gzip_stage4.log
build_package "Make" ./make.sh $LFS/sources/make_stage4.log
build_package "Patch" ./patch.sh $LFS/sources/patch_stage4.log
build_package "Sed" ./sed.sh $LFS/sources/sed_stage4.log
build_package "Tar" ./tar.sh $LFS/sources/tar_stage4.log
build_package "Xz" ./xz.sh $LFS/sources/xz_stage4.log
build_package "Binutils" ./binutils.sh $LFS/sources/binutils_stage4.log
build_package "GCC" ./gcc.sh $LFS/sources/gcc_stage4.log

