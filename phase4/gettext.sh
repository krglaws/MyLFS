#!/usr/bin/env bash
# Gettext Stage 6
# ~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep GETTEXT $PACKAGE_LIST)"
PKG_GETTEXT=$(basename $PKG_GETTEXT)

tar -xf $PKG_GETTEXT
cd ${PKG_GETTEXT%.tar*}

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.21

make

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIG/gettext.log
    set -e
fi

make install
chmod 0755 /usr/lib/preloadable_libintl.so

cd /sources
rm -rf ${PKG_GETTEXT%.tar*}

