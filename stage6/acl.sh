#!/usr/bin/env bash
# Acl Stage 6
# ~~~~~~~~~~
set -e

cd /sources

eval "$(grep ACL $PACKAGE_LIST)"
PKG_ACL=$(basename $PKG_ACL)

tar -xf $PKG_ACL
cd ${PKG_ACL%.tar*}

./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/usr/share/doc/acl-2.3.1

make

make install

cd /sources
rm -rf ${PKG_ACL%.tar*}

