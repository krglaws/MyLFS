#!/usr/bin/env bash
# Libcap Stage 6
# ~~~~~~~~~~
set -e

cd /sources

eval "$(grep LIBCAP $PACKAGE_LIST)"
PKG_LIBCAP=$(basename $PKG_LIBCAP)

tar -xf $PKG_LIBCAP
cd ${PKG_LIBCAP%.tar*}



cd /sources
rm -rf ${PKG_LIBCAP%.tar*}

