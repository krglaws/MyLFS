#!/usr/bin/env bash
# Sysvinit Stage 6
# ~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep SYSVINIT $PACKAGE_LIST)"
PKG_SYSVINIT=$(basename $PKG_SYSVINIT)
PATCH_SYSVINIT=$(basename $PATCH_SYSVINIT)

tar -xf $PKG_SYSVINIT
cd ${PKG_SYSVINIT%.tar*}

patch -Np1 -i ../$PATCH_SYSVINIT

make

make install

cd /sources
rm -rf ${PKG_SYSVINIT%.tar*}

