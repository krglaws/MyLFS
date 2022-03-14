#!/usr/bin/env bash
# IPRoute2 Stage 6
# ~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep IPROUTE2 $PACKAGE_LIST)"
PKG_IPROUTE2=$(basename $PKG_IPROUTE2)

tar -xf $PKG_IPROUTE2
cd ${PKG_IPROUTE2%.tar*}

sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8

make

make SBINDIR=/usr/sbin install

mkdir -pv             /usr/share/doc/iproute2-5.16.0
cp -v COPYING README* /usr/share/doc/iproute2-5.16.0

cd /sources
rm -rf ${PKG_IPROUTE2%.tar*}

