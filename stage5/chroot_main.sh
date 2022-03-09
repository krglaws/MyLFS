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

cd /sources/stage5

build_package "libstdcpp" ./libstdcpp.sh /sources/libstdcpp_stage5.log
build_package "Gettext" ./gettext.sh /sources/gettext_stage5.log
build_package "Bison" ./bison.sh /sources/bison_stage5.log
build_package "Perl" ./perl.sh /sources/perl_stage5.log
build_package "Python" ./python.sh /sources/python_stage5.log
build_package "Texinfo" ./texinfo.sh /sources/texinfo_stage5.log
build_package "Util Linux" ./util_linux.sh /sources/util_linux_stage5.log

# Cleanup
rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tools

