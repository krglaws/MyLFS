#!/usr/bin/bash
# main.sh
# ~~~~~~~
# This is the main entry point for this project.
set -e

if [ "$UID" != "0" ]
then
    echo "ERROR: $0 must be run as root."
    exit -1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

source $SCRIPT_DIR/config/global.sh

echo "Starting Stage 1..."
if ! $SCRIPT_DIR/stage1/main.sh
then
    echo "Stage 1 failed."
    exit -1
fi
echo "Completed Stage 1."

echo "Starting Stage 2..."
if ! $SCRIPT_DIR/stage2/main.sh
then
    echo "Stage 2 failed."
    exit -1
fi
echo "Completed Stage 2."

echo "Starting Stage 3..."
if ! su $LFS_USER --shell=/usr/bin/bash --command\
    "source $SCRIPT_DIR/config/global.sh && source $SCRIPT_DIR/config/user.sh && $SCRIPT_DIR/stage3/main.sh"
then
    echo "Stage 3 failed."
    exit -1
fi
echo "Completed Stage 3."

