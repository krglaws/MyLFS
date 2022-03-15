#!/usr/bin/env bash
# Expect Stage 6
# ~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep EXPECT $PACKAGE_LIST)"
PKG_EXPECT=$(basename $PKG_EXPECT)

tar -xf $PKG_EXPECT
cd ${PKG_EXPECT%.tar*}

./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include

make

if $RUN_TESTS
then
    set +e
    make test &> $TESTLOG_DIR/expect.log
    set -e
fi

make install

ln -sf expect5.45.4/libexpect5.45.4.so /usr/lib

cd /sources
rm -rf ${PKG_EXPECT%.tar*}

