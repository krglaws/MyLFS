#!/usr/bin/bash
set -e

if [ "$UID" != "0" ]
then
    echo "ERROR: $0 must be run as root."
    exit -1
fi

source ./config.sh

echo "Starting Stage 1..."
stage1/main.sh
echo "Completed Stage 1."

echo "Starting Stage 2..."
stage2/main.sh
echo "Completed Stage 2."

echo "Starting Stage 3..."
su $LFS_USER --login --shell=/usr/bin/bash --command="source ./config.sh && source ./user_config.sh && stage3/main.sh"
echo "Completed Stage 3."

