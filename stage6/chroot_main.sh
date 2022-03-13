# This script will be loaded into the $LFS/sources directory
# where it will be executed by a chroot shell.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set -e
echo "done."

# This is copied from config/user.sh since I'm too lazy to
# figure out a way to pass it into the chroot environment.
function build_package {
    PACKAGE_NAME=$1
    BUILD_SCRIPT=$2
    BUILD_LOG=$3

    echo -n "Building ${PACKAGE_NAME}... "
    if ! { $BUILD_SCRIPT &> $BUILD_LOG && rm $BUILD_LOG && echo "done."; }
    then
        echo "failed. Check $BUILD_LOG for more information."
        exit -1
    fi
}

cd /sources/stage6

build_package "Man Pages" ./man.sh /sources/man_stage6.log

