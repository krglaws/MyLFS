#!/usr/bin/env bash
# Gettext Stage 5
# ~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep GETTEXT $PACKAGE_LIST)"
PKG_GETTEXT=$(basename $PKG_GETTEXT)

tar -xf $PKG_GETTEXT
cd ${PKG_GETTEXT%.tar*}

./configure --disable-shared

make

cp gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

cd /sources
rm -rf ${PKG_GETTEXT%.tar*}

