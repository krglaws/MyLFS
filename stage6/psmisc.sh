#!/usr/bin/env bash
# Psmisc Stage 6
# ~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep PSMISC $PACKAGE_LIST)"
PKG_PSMISC=$(basename $PKG_PSMISC)

tar -xf $PKG_PSMISC
cd ${PKG_PSMISC%.tar*}

./configure --prefix=/usr

make

make install

cd /sources
rm -rf ${PKG_PSMISC%.tar*}

