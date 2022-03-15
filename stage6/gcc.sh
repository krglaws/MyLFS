#!/usr/bin/env bash
# GCC Stage 6
# ~~~~~~~~~~~
set -e

cd /sources

eval "$(grep GCC $PACKAGE_LIST)"
PKG_GCC=$(basename $PKG_GCC)

tar -xf $PKG_GCC
cd ${PKG_GCC%.tar*}

sed -e '/static.*SIGSTKSZ/d' \
    -e 's/return kAltStackSize/return SIGSTKSZ * 4/' \
    -i libsanitizer/sanitizer_common/sanitizer_posix_libcdep.cpp

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

mkdir build
cd build

make

ulimit -s 32768


if $RUN_TESTS
then
    set +e
    chown -R tester .
    su tester -c "PATH=$PATH make -k check" &> $TESTLOG_DIR/gcc.log
    set -e
fi

make install
rm -rf /usr/lib/gcc/$(gcc -dumpmachine)/11.2.0/include-fixed/bits/

chown -R root:root \
    /usr/lib/gcc/*linux-gnu/11.2.0/include{,-fixed}

ln -sr /usr/bin/cpp /usr/lib

ln -sf ../../libexec/gcc/$(gcc -dumpmachine)/11.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/

echo 'int main(){}' > dummy.c
cc dummy.c -Wl,--verbose &> dummy.log

rm dummy.c a.out dummy.log

mkdir -p /usr/share/gdb/auto-load/usr/lib
mv /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

cd /sources
rm -rf ${PKG_GCC%.tar*}

