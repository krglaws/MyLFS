#!/usr/bin/env bash
# Inetutils Stage 6
# ~~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep INETUTILS $PACKAGE_LIST)"
PKG_INETUTILS=$(basename $PKG_INETUTILS)

tar -xf $PKG_INETUTILS
cd ${PKG_INETUTILS%.tar*}

./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers

make

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/inetutils.log
    set -e
fi

make install

mv /usr/{,s}bin/ifconfig

cd /sources
rm -rf ${PKG_BC%.tar*}

