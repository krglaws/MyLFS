# LFS User shell configuration file.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set +h
umask 022

PATH=/usr/bin
if [ ! -L /bin ]
then
    PATH=/bin:$PATH
fi
PATH=$LFS/tools/bin:$PATH

CONFIG_SITE=$LFS/usr/share/config.site
LC_ALL=POSIX

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

export -f build_package
export LC_ALL PATH CONFIG_SITE

