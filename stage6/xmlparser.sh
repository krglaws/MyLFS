#!/usr/bin/env bash
# XML::Parser Stage 6
# ~~~~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep XMLPARSER $PACKAGE_LIST)"
PKG_XMLPARSER=$(basename $PKG_XMLPARSER)

tar -xf $PKG_XMLPARSER
cd ${PKG_XMLPARSER%.tar*}

perl Makefile.PL

make

make test

make install

cd /sources
rm -rf ${PKG_XMLPARSER%.tar*}

