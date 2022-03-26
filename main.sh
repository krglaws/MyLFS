#!/usr/bin/env bash
set -e
cd $(dirname $0)

source ./config.sh

while read pkg;
do
    eval $pkg
    export $(echo $pkg | cut -d"=" -f1)
done < ./pkgs.sh

./clean_img.sh


# #########
# Functions
# ~~~~~~~~~

function compare_version {
    local MINVERS=$1
    local CURRVERS=$2
    local NDIGS=$(echo $MINVERS | tr . ' ' | wc -w)

    for ((FIELD=1; FIELD < NDIGS; FIELD++))
    do
        MINDIGIT=$(echo $MINVERS | cut -d"." -f$FIELD)
        CURRDIGIT=$(echo $CURRVERS | cut -d"." -f$FIELD)
        if [[ "0x$CURRDIGIT" -gt "0x$MINDIGIT" ]]
        then
            return 0
        elif [[ "0x$CURRDIGIT" -eq "0x$MINDIGIT" ]]
        then
            continue
        else
            return -1
        fi
    done

    return 0
}

function check_dependency {
    local PROG=$1
    local MINVERS=$2
    local CURRVERSFIELD=$3

    if ! command -v $PROG 1 > /dev/null
    then
        echo "ERROR: '$PROG' not found"
        return -1
    fi

    CURRVERS=$($PROG --version 2>&1 | head -n1 | cut -d" " -f$CURRVERSFIELD | cut -d"(" -f1 | cut -d"," -f1 | cut -d"-" -f1)
    CURRVERS=${CURRVERS%"${CURRVERS##*[0-9]}"}

    if ! compare_version "$MINVERS" "$CURRVERS"
    then
        echo "ERROR: $PROG $CURRVERS does not satisfy minimum version $MINVERS"
    fi
}

function get_packages {
    PACKAGE_URLS=$(cat $PACKAGE_LIST | cut -d"=" -f2)
    PACKAGES=$(ls ./pkgs)

    # check if packages have already been downloaded
    if [ -z "$PACKAGES" ]
    then
# no indent because here-doc
wget --quiet --directory-prefix $PACKAGE_DIR --input-file - <<EOF
$PACKAGE_URLS
EOF
    fi

    cp $PACKAGE_DIR/* $LFS/sources
}

function install_static {
    FILENAME=$1
    FULLPATH="$LFS/$(basename $FILENAME | sed 's/__/\//g')"
    mkdir -p $(dirname $FULLPATH)
    cp $FILENAME $FULLPATH
}

function install_template {
    FILENAME=$1
    FULLPATH="$LFS/$(basename $FILENAME | sed 's/__/\//g')"
    mkdir -p $(dirname $FULLPATH)
    cp $FILENAME $FULLPATH
    shift
    for var in $@
    do
        sed -i "s/$var/${!var}/g" $FULLPATH
    done
}

function build_package {
    NAME=$1
    OVERRIDE=$2

    echo -n "Building $NAME phase $PHASE... "

    PKG_NAME=PKG_$([ -n "$OVERRIDE" ] && echo $OVERRIDE || echo $NAME | tr a-z A-Z)
    PKG_NAME=$(basename ${!PKG_NAME})

    PATCH_NAME=PATCH_$([ -n "$OVERRIDE" ] && echo $OVERRIDE || echo $NAME | tr a-z A-Z)
    PATCH_NAME=$([ -n "${!PATCH_NAME}" ] && basename ${!PATCH_NAME} || echo "")

    DIR_NAME=${PKG_NAME%.tar*}
    LOG_FILE=$LOG_DIR/${NAME}_phase${PHASE}.log

    BUILD_INSTR="
        set -e
        pushd sources > /dev/null
        tar -xf $PKG_NAME
        cd $DIR_NAME
        $(cat ./phase${PHASE}/${NAME}.sh)
        popd
        rm -r sources/$DIR_NAME
    "

    pushd $LFS > /dev/null
    if $CHROOT
    then
        if ! chroot "$LFS" /usr/bin/env -i \
                HOME=/root \
                TERM=$TERM \
                PATH=/usr/bin:/usr/sbin &> $LOG_FILE \
                LFS_TGT=$LFS_TGT \
                ROOT_PASSWD=$ROOT_PASSWD \
                RUN_TESTS=$RUN_TESTS \
                "$(cat $PACKAGE_LIST)" \
                /bin/bash +h -c "$BUILD_INSTR" &> $LOG_FILE
        then
            echo -e "\nERROR: $NAME Phase $PHASE failed:"
            tail $LOG_FILE
            return -1
        fi
    elif ! (eval "$BUILD_INSTR") &> $LOG_FILE
    then
        echo -e "\nERROR: $NAME Phase $PHASE failed:"
        tail $LOG_FILE
        return -1
    fi
    popd > /dev/null

    (cd $LOG_DIR && gzip $LOG_FILE)

    echo "done."

    return 0
}


# #########################
# Check system dependencies
# ~~~~~~~~~~~~~~~~~~~~~~~~~

EXIT_STATUS=0

echo -n "Checking system dependencies... "

if ! check_dependency bash       3.2     4; then EXIT_STATUS=-1; fi
if ! check_dependency ld         2.13.1  7; then EXIT_STATUS=-1; fi  # binutils
if ! check_dependency bison      2.7     4; then EXIT_STATUS=-1; fi
if ! check_dependency chown      6.9     4; then EXIT_STATUS=-1; fi  # coreutils
if ! check_dependency diff       2.8.1   4; then EXIT_STATUS=-1; fi
if ! check_dependency find       4.2.31  4; then EXIT_STATUS=-1; fi
if ! check_dependency gawk       4.0.1   3; then EXIT_STATUS=-1; fi
if ! check_dependency gcc        4.8     4; then EXIT_STATUS=-1; fi
if ! check_dependency g++        4.8     4; then EXIT_STATUS=-1; fi
if ! check_dependency grep       2.5.1a  4; then EXIT_STATUS=-1; fi
if ! check_dependency gzip       1.3.12  2; then EXIT_STATUS=-1; fi
if ! check_dependency m4         1.4.10  4; then EXIT_STATUS=-1; fi
if ! check_dependency make       4.0     3; then EXIT_STATUS=-1; fi
if ! check_dependency patch      2.5.4   3; then EXIT_STATUS=-1; fi
if ! check_dependency python3    3.4     2; then EXIT_STATUS=-1; fi
if ! check_dependency sed        4.1.5   4; then EXIT_STATUS=-1; fi
if ! check_dependency tar        1.22    4; then EXIT_STATUS=-1; fi
if ! check_dependency makeinfo   4.7     4; then EXIT_STATUS=-1; fi  # texinfo
if ! check_dependency xz         5.0.0   4; then EXIT_STATUS=-1; fi

# check that yacc is a link to bison
if [ ! -h /usr/bin/yacc -a "$(readlink -f /usr/bin/yacc)"="/usr/bin/bison.yacc" ]
then
    echo "ERROR: /usr/bin/yacc needs to be a link to /usr/bin/bison.yacc"
    EXIT_STATUS=-1
fi

# check that awk is a link to gawk
if [ ! -h /usr/bin/awk -a "$(readlink -f /usr/bin/awk)"="/usr/bin/gawk" ]
then
    echo "ERROR: /usr/bin/awk needs to be a link to /usr/bin/gawk"
    EXIT_STATUS=-1
fi

# check linux version
MIN_LINUX_VERS=3.2
LINUX_VERS=$(cat /proc/version | head -n1 | cut -d" " -f3 | cut -d"-" -f1)
if ! compare_version "$MIN_LINUX_VERSION" "$LINUX_VERS"
then
    echo "ERROR: Linux kernel version '$LINUX_VERS' does not satisfy minium version $MIN_LINUX_VERS"
    EXIT_STATUS=-1
fi

# check perl version
MIN_PERL_VERS=5.8.8
PERL_VERS=$(perl -V:version | cut -d"'" -f2)
if ! compare_version "$MIN_PERL_VERS" "$PERL_VERS"
then
    echo "ERROR: Perl version '$PERL_VERS' does not satisfy minium version $MIN_PERL_VERS"
    EXIT_STATUS=-1
fi

# check G++ compilation
echo 'int main(){}' > dummy.c && g++ -o dummy dummy.c
if [ ! -x dummy ]
then
    echo "ERROR: g++ compilation failed"
    EXIT_STATUS=-1
fi
rm -f dummy.c dummy

echo "done."

[ "$EXIT_STATUS" == "0" ] || exit $EXIT_STATUS


# ####################
# Create OS image file
# ~~~~~~~~~~~~~~~~~~~~

echo -n "Creating image file... "

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
LOOP_P1=${LOOP}p1
LOOP_P2=${LOOP}p2

# setup root partition
mkfs -t $LFS_FS $LOOP_P2 &> /dev/null
mkdir -p $LFS
mount $LOOP_P2 $LFS

# setup EFI partition
mkfs.vfat $LOOP_P1 &> /dev/null
mkdir -p $LFS/boot/efi
mount -t vfat $LOOP_P1 $LFS/boot/efi

# label the partitions
dosfslabel $LOOP_P1 $LFSEFILABEL &> /dev/null
e2label $LOOP_P2 $LFSROOTLABEL 

echo "done."


# #######################
# Basic file system setup
# ~~~~~~~~~~~~~~~~~~~~~~~

echo -n "Creating basic directory layout... "

mkdir -p $LFS/{bin,boot,dev,etc,home,lib64,media,mnt,opt,proc,run,srv,sys,tools,usr,var}
mkdir -p $LFS/boot/grub
mkdir -p $LFS/etc/{modprobe.d,opt,sysconfig}
mkdir -p $LFS/media/{cdrom,floppy}
mkdir -p $LFS/usr/{bin,lib/{,firmware},sbin}
mkdir -p $LFS/usr/local/{bin,include,lib,sbin,share,src}
mkdir -p $LFS/usr/local/share/{color,dict,doc,info,locale,man,misc,terminfo,zoneinfo}
mkdir -p $LFS/usr/local/share/man/{1..8}
mkdir -p $LFS/var/{cache,lib,local,log,mail,opt,spool}
mkdir -p $LFS/var/lib/{color,misc,locate}

install -d -m 0750 $LFS/root
install -d -m 1777 $LFS/tmp $LFS/var/tmp

# removed at end of build
mkdir -p $LFS/home/tester
chown 101:101 $LFS/home/tester
mkdir -p $LFS/sources

# create symlinks
for i in bin lib sbin
do
    ln -s usr/$i $LFS/$i
done
ln -s /run $LFS/var/run
ln -s /run/lock $LFS/var/lock
ln -s /proc/self/mounts $LFS/etc/mtab

# install static files
echo $LFSHOSTNAME > $LFS/etc/hostname
for file in ./static/*
do
    install_static $file
done

# install templates
install_template ./templates/boot__grub__grub.cfg LFSROOTLABEL
install_template ./templates/etc__fstab LFSROOTLABEL LFSEFILABEL LFSFSTYPE
install_template ./templates/etc__hosts LFSHOSTNAME

# make special device files
mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3

# create login log files
touch $LFS/var/log/{btmp,lastlog,faillog,wtmp}
chgrp 13 $LFS/var/log/lastlog
chmod 664  $LFS/var/log/lastlog
chmod 600  $LFS/var/log/btmp

# mount stuff from the host onto the target disk
mount --bind /dev $LFS/dev
mount --bind /dev/pts $LFS/dev/pts
mount -t proc proc $LFS/proc
mount -t sysfs sysfs $LFS/sys
mount -t tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  mkdir -p $LFS/$(readlink $LFS/dev/shm)
fi

echo "done."

echo -n "Downloading packages to $LFS/sources... "
get_packages
echo "done."


# ######################
# Setup environment vars
# ~~~~~~~~~~~~~~~~~~~~~~

TMP_PATH=$PATH
PATH=/usr/bin
if [ ! -L /bin ];
then
    PATH=/bin:$PATH;
fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
LC_ALL=POSIX
export LC_ALL PATH CONFIG_SITE

echo -e \
"# #######\n"\
"# Phase 1\n"\
"# ~~~~~~~"

CHROOT=false
PHASE=1
build_package binutils
build_package gcc
build_package linux_headers LINUX
build_package glibc
build_package libstdcpp GCC

echo -e \
"# #######\n"\
"# Phase 2\n"\
"# ~~~~~~~"

PHASE=2
build_package m4
build_package ncurses
build_package bash
build_package coreutils
build_package diffutils
build_package file
build_package findutils
build_package gawk
build_package grep
build_package gzip
build_package make
build_package patch
build_package sed
build_package tar
build_package xz
build_package binutils
build_package gcc

echo -e \
"# #######\n"\
"# Phase 3\n"\
"# ~~~~~~~"

PATH=$TMP_PATH
CHROOT=true
PHASE=3
build_package libstdcpp GCC
build_package gettext
build_package bison
build_package perl
build_package python
build_package texinfo
build_package utillinux

# Cleanup
rm -rf $LFS/usr/share/{info,man,doc}/*
find $LFS/usr/{lib,libexec} -name \*.la -delete
rm -rf $LFS/tools

echo -e \
"# #######\n"\
"# Phase 4\n"\
"# ~~~~~~~"

exit

PHASE=4
build_package manpages
build_package ianaetc
build_package glibc
build_package zlib
build_package bzip2
build_package xz
build_package zstd
build_package file
build_package readline
build_package m4
build_package bc
build_package flex
build_package tcl
build_package expect
build_package dejagnu
build_package binutils
build_package gmp
build_package mpfr
build_package mpc
build_package attr
build_package acl
build_package libcap
build_package shadow
build_package gcc
build_package pkgconfig
build_package ncurses
build_package sed
build_package psmisc
build_package gettext
build_package bison
build_package grep
build_package bash
build_package libtool
build_package gdbm
build_package gperf
build_package expat
build_package inetutils
build_package less
build_package perl
build_package xmlparser
build_package intltool
build_package autoconf
build_package automake
build_package openssl
build_package kmod
build_package elfutils
build_package libffi
build_package python
build_package ninja
build_package meson
build_package coreutils
build_package check
build_package diffutils
build_package gawk
build_package findutils
build_package groff
# Skipping GRUB MBR build since we are using UEFI
build_package gzip
build_package iproute2
build_package kbd
build_package libpipeline
build_package make
build_package patch
build_package tar
build_package texinfo
build_package vim
build_package eudev
build_package mandb
build_package procps
build_package utillinux
build_package e2fsprogs
build_package sysklogd
build_package sysvinit
build_package lfsbootscripts

# UEFI Boot Dependencies
build_pakcage popt
build_package mandoc
build_package efivar
build_package efibootmgr
build_package grub

# delete tmp files created during builds
rm -rf $LFS/tmp/*

# delete libtool archives (only useful when linking to static libs)
find $LFS/usr/lib $LFS/usr/libexec -name \*.la -delete

# delete cross compiler tools from previous stages
find $LFS/usr -depth -name $LFS_TGT\* | xargs rm -rf

# remove 'tester' user account
rm -r $LFS/home/tester
sed -i 's/^.*tester.*$//' $LFS/etc/{passwd,group}

