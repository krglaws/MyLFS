#!/usr/bin/env bash
# Stage 4
# ~~~~~~~
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

cd $(get_script_dir $BASH_SOURCE)

su $LFS_USER --shell=/usr/bin/bash --command \
"source ../config/global.sh "\
"&& source ../config/user.sh "\
"&& ./lfs_main.sh"

