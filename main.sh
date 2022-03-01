#!/usr/bin/bash
set -e

if [ "$UID" != "0" ]
then
    echo "ERROR: $0 must be run as root."
    exit -1
fi

source ./config.sh

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Starting Stage 1..."
stage1/main.sh
echo "Completed Stage 1."

echo "Starting Stage 2..."
stage2/main.sh
echo "Completed Stage 2."

echo "Starting Stage 3..."
set -x
su $LFS_USER --shell=/usr/bin/bash --command\
    "source $SCRIPT_DIR/config.sh && source $SCRIPT_DIR/user_config.sh && $SCRIPT_DIR/stage3/main.sh"
set +x
echo "Completed Stage 3."

