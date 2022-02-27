#!/usr/bin/bash
set -e

if [ "$UID" != "0" ]
then
    echo "ERROR: $0 must be executed as root"
    exit -1
fi

if [ -z "$LFS" -o -z "$LFS_USER" ]
then
    echo "ERROR: Missing config vars. Be sure to source config.sh before running this script."
    exit -1
fi

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Checking dependency versions..."
$SCRIPT_DIR/check_dep_versions.sh
echo "Done."

echo "Building image..."
$SCRIPT_DIR/build_img.sh
echo "Done."

