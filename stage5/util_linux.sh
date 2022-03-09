#!/usr/bin/env bash
# Util Linux Stage 5
# ~~~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep UTILLINUX $PACKAGE_LIST)"
PKG_UTILLINUX=$(basename $PKG_UTILLINUX)

tar -xf $PKG_UTILLINUX
cd ${PKG_UTILLINUX%.tar*}

mkdir -p /var/lib/hwclock

./configure ADJTIME_PATH=/var/lib/hwclock/adjtime    \
            --libdir=/usr/lib    \
            --docdir=/usr/share/doc/util-linux-2.37.4 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            runstatedir=/run

make
make install

cd /sources
rm -rf ${PKG_UTILLINUX%.tar*}

