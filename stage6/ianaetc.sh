#!/usr/bin/env bash
# Iana-Etc Stage 6
# ~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep IANAETC $PACKAGE_LIST)"
PKG_IANAETC=$(basename $PKG_IANAETC)

tar -xf $PKG_IANAETC
cd ${PKG_IANAETC%.tar*}

cp services protocols /etc

cd /sources
rm -rf ${PKG_IANAETC%.tar*}

