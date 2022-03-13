#!/usr/bin/env bash
# DejaGNU Stage 6
# ~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep DEJAGNU $PACKAGE_LIST)"
PKG_DEJAGNU=$(basename $PKG_DEJAGNU)

tar -xf $PKG_DEJAGNU
cd ${PKG_DEJAGNU%.tar*}

mkdir build
cd       build

../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi

make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3

make check

cd /sources
rm -rf ${PKG_DEJAGNU%.tar*}

