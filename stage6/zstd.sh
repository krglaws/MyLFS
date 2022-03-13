#!/usr/bin/env bash
# Zstd Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep ZSTD $PACKAGE_LIST)"
PKG_ZSTD=$(basename $PKG_ZSTD)

tar -xf $PKG_ZSTD
cd ${PKG_ZSTD%.tar*}

make
make check
make PREFIX=/usr install
rm /usr/lib/libzstd.a

cd /sources
rm -rf ${PKG_ZSTD%.tar*}

