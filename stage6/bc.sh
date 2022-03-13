#!/usr/bin/env bash
# Bc Stage 6
# ~~~~~~~~~~
set -e

cd /sources

eval "$(grep BC $PACKAGE_LIST)"
PKG_BC=$(basename $PKG_BC)

tar -xf $PKG_BC
cd ${PKG_BC%.tar*}

CC=gcc ./configure --prefix=/usr -G -O3

make

make test

make install

cd /sources
rm -rf ${PKG_BC%.tar*}

