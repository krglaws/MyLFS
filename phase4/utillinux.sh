#!/usr/bin/env bash
# Util-linux Stage 6
# ~~~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep UTILLINUX $PACKAGE_LIST)"
PKG_UTILLINUX=$(basename $PKG_UTILLINUX)

tar -xf $PKG_UTILLINUX
cd ${PKG_UTILLINUX%.tar*}

./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
            --bindir=/usr/bin    \
            --libdir=/usr/lib    \
            --sbindir=/usr/sbin  \
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
            --without-systemd    \
            --without-systemdsystemunitdir

make

if $RUN_TESTS
then
    set +e
    chown -Rv tester .
    su tester -c "make -k check" &> $TESTLOG_DIR/utillinux.log
    set -e
fi

make install

cd /sources
rm -rf ${PKG_UTILLINUX%.tar*}

