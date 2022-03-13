#!/usr/bin/env bash
# Stage 6
# ~~~~~~~
# This stage covers chapter 8. This will build the final set of
# packages in LFS.
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

BUILD_SCRIPTS=$(find . ! -name "main.sh" -a ! -name ".")

mkdir $LFS/sources/stage6
cp $BUILD_SCRIPTS $CONF_DIR/pkgs.sh $LFS/sources/stage6
chmod +x $LFS/sources/stage6/*.sh

echo -n "Entering chroot environment... "

chroot "$LFS" /usr/bin/env -i               \
    HOME=/root                              \
    TERM="$TERM"                            \
    PS1='(lfs chroot) \u:\w\$ '             \
    PATH=/usr/bin:/usr/sbin                 \
    LFS_TGT=$LFS_TGT                        \
    PACKAGE_LIST=/sources/stage6/pkgs.sh    \
    /bin/bash +h -c "/sources/stage6/chroot_main.sh"

