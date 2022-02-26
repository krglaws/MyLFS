#/usr/bin/env bash
set -e

if [ -z "$LFS_USR" ]
then
    echo "LFS_USR var not set. Be sure to source config.sh before running this script."
    exit -1
fi

if [ "$LFS_USR" != "$USER" ]
then
    echo "This script needs to be run as $LFS_USR."
    exit -1
fi

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

$SCRIPT_DIR/binutils.sh
$SCRIPT_DIR/gcc.sh
$SCRIPT_DIR/linux_headers.sh
$SCRIPT_DIR/glibc.sh
$SCRIPT_DIR/libstdcpp.sh

echo "Done."

