#!/usr/bin/env bash
# Bzip2 Stage 6
# ~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep BZIP2 $PACKAGE_LIST)"
PKG_BZIP2=$(basename $PKG_BZIP2)

tar -xf $PKG_BZIP2
cd ${PKG_BZIP2%.tar*}

patch -Np1 -i ../$PATCH_BZIP2
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install
cp -a libbz2.so.* /usr/lib
ln -s libbz2.so.1.0.8 /usr/lib/libbz2.so
cp bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sf bzip2 $i
done
rm -f /usr/lib/libbz2.a

cd /sources
rm -rf ${PKG_BZIP2%.tar*}

