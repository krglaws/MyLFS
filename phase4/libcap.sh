#!/usr/bin/env bash
# Libcap Stage 6
# ~~~~~~~~~~
set -e

cd /sources

eval "$(grep LIBCAP $PACKAGE_LIST)"
PKG_LIBCAP=$(basename $PKG_LIBCAP)

tar -xf $PKG_LIBCAP
cd ${PKG_LIBCAP%.tar*}

sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib

if $RUN_TESTS
then
    set +e
    make test &> $TESTLOG_DIR/libcap.log
    set -e
fi

make prefix=/usr lib=lib install

cd /sources
rm -rf ${PKG_LIBCAP%.tar*}

