#!/usr/bin/env bash
# LFS Boot Scripts Stage 6
# ~~~~~~~~~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep LFSBOOTSCRIPTS $PACKAGE_LIST)"
PKG_LFSBOOTSCRIPTS=$(basename $PKG_LFSBOOTSCRIPTS)

tar -xf $PKG_LFSBOOTSCRIPTS
cd ${PKG_LFSBOOTSCRIPTS%.tar*}

make install

# generate network interface name rules
bash /usr/lib/udev/init-net-rules.sh

cd /sources
rm -rf ${PKG_LFSBOOTSCRIPTS%.tar*}

