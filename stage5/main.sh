#!/usr/bin/env bash
# Stage 5
# ~~~~~~~
# This stage roughly covers chapter 7, which
# involves mounting a few files and directories
# from the host system into the $LFS filesystem
# tree, entering the chroot environment, and building
# additional temporary tools.
set -e

if [ "$UID" != "0" ]
then
    echo "ERROR: $0 must be run as root."
    exit -1
fi

if [ -z "$LFS" ]
then
    echo "ERROR: $0: Missing config vars."
    exit -1
fi

if [ -z "$(mount | grep $LFS)" ]
then
    echo "ERROR: $LFS_IMG does not appear to be mounted on $LFS."
    exit -1
fi

cd $(dirname $0)

echo -n "Performing final environment setup... "

chown -R root:root $LFS/*
chown 101:101 $LFS/home/tester

mount --bind /dev $LFS/dev
mount --bind /dev/pts $LFS/dev/pts

mount -t proc proc $LFS/proc
mount -t sysfs sysfs $LFS/sys
mount -t tmpfs tmpfs $LFS/run

BUILD_SCRIPTS=$(find . ! -name "main.sh" -a ! -name ".")

mkdir $LFS/sources/stage5
cp $BUILD_SCRIPTS $CONF_DIR/pkgs.sh $LFS/sources/stage5
chmod +x $LFS/sources/stage5/*.sh

echo "done."

echo -n "Entering chroot environment... "

chroot "$LFS" /usr/bin/env -i               \
    HOME=/root                              \
    TERM="$TERM"                            \
    PS1='(lfs chroot) \u:\w\$ '             \
    PATH=/usr/bin:/usr/sbin                 \
    LFS_TGT=$LFS_TGT                        \
    PACKAGE_LIST=/sources/stage5/pkgs.sh    \
    /bin/bash +h -c "/sources/stage5/chroot_main.sh"

rm -r $LFS/sources/stage5

