#!/usr/bin/env bash
# Findutils Stage 6
# ~~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep FINDUTILS $PACKAGE_LIST)"
PKG_FINDUTILS=$(basename $PKG_FINDUTILS)

tar -xf $PKG_FINDUTILS
cd ${PKG_FINDUTILS%.tar*}

case $(uname -m) in
    i?86)   TIME_T_32_BIT_OK=yes ./configure --prefix=/usr --localstatedir=/var/lib/locate ;;
    x86_64) ./configure --prefix=/usr --localstatedir=/var/lib/locate ;;
esac

make

if $RUN_TESTS
then
    set +e
    chown -R tester .
    su tester -c "PATH=$PATH make check" &> $TESTLOG_DIR/findutils.log
    set -e
fi

make install

cd /sources
rm -rf ${PKG_FINDUTILS%.tar*}
