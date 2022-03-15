#!/usr/bin/env bash
# Elfutils Stage 6
# ~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep ELFUTILS $PACKAGE_LIST)"
PKG_ELFUTILS=$(basename $PKG_ELFUTILS)

tar -xf $PKG_ELFUTILS
cd ${PKG_ELFUTILS%.tar*}

./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy

make

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/elfutils.log
    set -e
fi

make -C libelf install
install -m644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a

cd /sources
rm -rf ${PKG_ELFUTILS%.tar*}

