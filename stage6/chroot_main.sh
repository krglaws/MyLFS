# This script will be loaded into the $LFS/sources directory
# where it will be executed by a chroot shell.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set -e
echo "done."

# This is copied from config/user.sh since I'm too lazy to
# figure out a way to pass it into the chroot environment.
function build_package {
    BUILD_SCRIPT=$1
    PACKAGE_NAME=${BUILD_SCRIPT%.sh}
    BUILD_LOG=/sources/${PACKAGE_NAME}_stage6.log

    echo -n "Building ${PACKAGE_NAME}... "
    if ! { $BUILD_SCRIPT &> $BUILD_LOG && rm $BUILD_LOG && echo "done."; }
    then
        echo "failed. Check $BUILD_LOG for more information."
        exit -1
    fi
}

mkdir -p $TESTLOG_DIR

cd /sources/stage6

build_package ./manpages.sh
build_package ./ianaetc.sh
build_package ./glibc.sh
build_package ./zlib.sh
build_package ./bzip2.sh
build_package ./xz.sh
build_package ./zstd.sh
build_package ./file.sh
build_package ./readline.sh
build_package ./m4.sh
build_package ./bc.sh
build_package ./flex.sh
build_package ./tcl.sh
build_package ./expect.sh
build_package ./dejagnu.sh
build_package ./binutils.sh
build_package ./gmp.sh
build_package ./mpfr.sh
build_package ./mpc.sh
build_package ./attr.sh
build_package ./acl.sh
build_package ./libcap.sh
build_package ./shadow.sh
build_package ./gcc.sh
build_package ./pkgconfig.sh
build_package ./ncurses.sh
build_package ./sed.sh
build_package ./psmisc.sh
build_package ./gettext.sh
build_package ./bison.sh
build_package ./grep.sh
build_package ./bash.sh
build_package ./libtool.sh
build_package ./gdbm.sh
build_package ./gperf.sh
build_package ./expat.sh
build_package ./inetutils.sh
build_package ./less.sh
build_package ./perl.sh
build_package ./xmlparser.sh
build_package ./intltool.sh
build_package ./autoconf.sh
build_package ./automake.sh
build_package ./openssl.sh
build_package ./kmod.sh
build_package ./elfutils.sh
build_package ./libffi.sh
build_package ./python.sh
build_package ./ninja.sh
build_package ./meson.sh
build_package ./coreutils.sh
build_package ./check.sh
build_package ./diffutils.sh
build_package ./gawk.sh
build_package ./findutils.sh
build_package ./groff.sh
# Skipping GRUB MBR build since we are using UEFI
build_package ./gzip.sh
build_package ./iproute2.sh
build_package ./kbd.sh
build_package ./libpipeline.sh
build_package ./make.sh
build_package ./patch.sh
build_package ./tar.sh
build_package ./texinfo.sh
build_package ./vim.sh
build_package ./eudev.sh
build_package ./mandb.sh
build_package ./procps.sh
build_package ./utillinux.sh
build_package ./e2fsprogs.sh
build_package ./sysklogd.sh
build_package ./sysvinit.sh
build_package ./lfsbootscripts.sh

# UEFI Boot Dependencies
build_pakcage ./popt.sh
build_package ./mandoc.sh
build_package ./efivar.sh
build_package ./efibootmgr.sh
build_package ./grub.sh

# delete temp files leftover from tests
rm -rf /tmp/*

# delete libtool archives (only useful when linking to static libs)
find /usr/lib /usr/libexec -name \*.la -delete

# delete cross compiler tools from previous stages
find /usr -depth -name $LFS_TGT\* | xargs rm -rf

# remove 'tester' user account
userdel -r tester

