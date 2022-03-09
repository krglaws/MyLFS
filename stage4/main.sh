#!/usr/bin/env bash
# Stage 4
# ~~~~~~~
# This stage covers chapter 6, which
# covers the 2nd pass compiler tool chain,
# and also builds packages necessary for
# supporting the chroot environment.
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

su $LFS_USER --shell=/usr/bin/bash --command \
"source $GLOBAL_CONF "\
"&& source $USER_CONF "\
"&& ./lfs_main.sh"

