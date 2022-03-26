#!/usr/bin/env bash
# MPC Stage 6
# ~~~~~~~~~~~
set -e

cd /sources

eval "$(grep MPC $PACKAGE_LIST)"
PKG_MPC=$(basename $PKG_MPC)

tar -xf $PKG_MPC
cd ${PKG_MPC%.tar*}

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.2.1

make
make html

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/mpc.log
    set -e
fi

make install
make install-html

cd /sources
rm -rf ${PKG_MPC%.tar*}
