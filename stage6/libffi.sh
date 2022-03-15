#!/usr/bin/env bash
# Libffi Stage 6
# ~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep LIBFFI $PACKAGE_LIST)"
PKG_LIBFFI=$(basename $PKG_LIBFFI)

tar -xf $PKG_LIBFFI
cd ${PKG_LIBFFI%.tar*}

./configure --prefix=/usr          \
            --disable-static       \
            --with-gcc-arch=native \
            --disable-exec-static-tramp

make

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/libffi.log
    set -e
fi

make install

cd /sources
rm -rf ${PKG_LIBFFI%.tar*}

