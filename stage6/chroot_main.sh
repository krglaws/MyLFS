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

build_package "Man Pages" ./manpages.sh /sources/manpages_stage6.log
build_package "Iana-Etc" ./ianaetc.sh /sources/ianaetc_stage6.log
build_package "Glibc" ./glibc.sh /sources/glibc_stage6.log
build_package "Zlib" ./zlib.sh /sources/zlib_stage6.log
build_package "Bzip2" ./bzip2.sh /sources/bzip2_stage6.log
build_package "Xz" ./xz.sh /sources/xz_stage6.log
build_package "Zstd" ./zstd.sh /sources/zstd_stage6.log
build_package "File" ./file.sh /sources/file_stage6.log
build_package "Readline" ./readline.sh /sources/readline_stage6.log
build_package "M4" ./m4.sh /sources/m4_stage6.log
build_package "Bc" ./bc.sh /sources/bc_stage6.log
build_package "Flex" ./flex.sh /sources/flex_stage6.log
build_package "Tcl" ./tcl.sh /sources/tcl_stage6.log
build_package "Expect" ./expect.sh /sources/expect_stage6.log
build_package "DejaGNU" ./dejagnu.sh /sources/dejagnu_stage6.log
build_package "Binutils" ./binutils.sh /sources/binutils_stage6.log
build_package "GMP" ./gmp.sh /sources/gmp_stage6.log
build_package "MPFR" ./mpfr.sh /sources/mpfr_stage6.log
build_package "MPC" ./mpc.sh /sources/mpc_stage6.log
build_package "Attr" ./attr.sh /sources/attr_stage6.log
build_package "Acl" ./acl.sh /sources/acl_stage6.log
build_package "Libcap" ./libcap.sh /sources/libcap_stage6.log
build_package "Shadow" ./shadow.sh /sources/shadow_stage6.log
build_package "GCC" ./gcc.sh /sources/gcc_stage6.log
build_package "Pkg-config" ./pkgconfig.sh /sources/pkgconfig_stage6.log
build_package "Ncurses" ./ncurses.sh /sources/ncurses_stage6.log
build_package "Sed" ./sed.sh /sources/sed_stage6.log
build_package "Psmisc" ./psmisc.sh /sources/psmisc_stage6.log
build_package "Gettext" ./gettext.sh /sources/gettext_stage6.log
build_package "Bison" ./bison.sh /sources/bison_stage6.log
build_package "Grep" ./grep.sh /sources/grep_stage6.log
build_package "Bash" ./bash.sh /sources/bash_stage6.log
build_package "Libtool" ./libtool.sh /sources/libtool_stage6.log
build_package "GDBM" ./gdbm.sh /sources/gdbm_stage6.log
build_package "Gperf" ./gperf.sh /sources/gperf_stage6.log
build_package "Expat" ./expat.sh /sources/expat_stage6.log
build_package "Inetutils" ./inetutils.sh /sources/inetutils_stage6.log
build_package "Less" ./less.sh /sources/less_stage6.log
build_package "Perl" ./perl.sh /sources/perl_stage6.log
build_package "XML::Parser" ./xmlparser.sh /sources/xmlparser_stage6.log
build_package "Intltool" ./intltool.sh /sources/intltool_stage6.log
build_package "Autoconf" ./autoconf.sh /sources/autoconf_stage6.log
build_package "Automake" ./automake.sh /sources/automake_stage6.log
build_package "OpenSSL" ./openssl.sh /sources/openssl_stage6.log
build_package "Kmod" ./kmod.sh /sources/kmod_stage6.log
build_package "Elfutils" ./elfutils.sh /sources/elfutils_stage6.log
build_package "Libffi" ./libffi.sh /sources/libffi_stage6.log
build_package "Python" ./python.sh /sources/python_stage6.log
build_package "Ninja" ./ninja.sh /sources/ninja_stage6.log
build_package "Meson" ./meson.sh /sources/meson_stage6.log
build_package "Coreutils" ./coreutils.sh /sources/coreutils_stage6.log
build_package "Check" ./check.sh /sources/check_stage6.log
build_package "Diffutils" ./diffutils.sh /sources/diffutils_stage6.log
build_package "Gawk" ./gawk.sh /sources/gawk_stage6.log
build_package "Findutils" ./findutils.sh /sources/findutils_stage6.log
build_package "Groff" ./groff.sh /sources/groff_stage6.log
# Skipping GRUB MBR build since we are using UEFI
build_package "Gzip" ./gzip.sh /sources/gzip_stage6.log
build_package "IPRoute2" ./iproute2.sh /sources/iproute2_stage6.log
build_package "Kbd" ./kbd.sh /sources/kbd_stage6.log
build_package "Libpipeline" ./libpipeline.sh /sources/libpipeline_stage6.log
build_package "Make" ./make.sh /sources/make_stage6.log
build_package "Patch" ./patch.sh /sources/patch_stage6.log
build_package "Tar" ./tar.sh /sources/tar_stage6.log
build_package "Texinfo" ./texinfo.sh /sources/texinfo_stage6.log
build_package "Vim" ./vim.sh /sources/vim_stage6.log
build_package "Eudev" ./eudev.sh /sources/eudev_stage6.log
build_package "Man-DB" ./mandb.sh /sources/mandb_stage6.log
build_package "Procps-ng" ./procpsng.sh /sources/procpsng_stage6.log
build_package "Util-linux" ./utillinux.sh /sources/utillinux_stage6.log
build_package "E2fsprogs" ./e2fsprogs.sh /sources/e2fsprogs_stage6.log
build_package "Sysklogd" ./sysklogd.sh /sources/sysklogd_stage6.log
build_package "Sysvinit" ./sysvinit.sh /sources/sysvinit_stage6.log

# delete temp files leftover from tests
rm -rf /tmp/*

# delete libtool archives (only useful when linking to static libs)
find /usr/lib /usr/libexec -name \*.la -delete

# delete cross compiler tools from previous stages
find /usr -depth -name $LFS_TGT\* | xargs rm -rf

# remove 'tester' user account
userdel -r tester

