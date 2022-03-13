#!/usr/bin/env bash
# Binutils Stage 6
# ~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep BINUTILS $PACKAGE_LIST)"
PKG_BINUTILS=$(basename $PKG_BINUTILS)

tar -xf $PKG_BINUTILS
cd ${PKG_BINUTILS%.tar*}

patch -Np1 -i ../binutils-2.38-lto_fix-1.patch

sed -e '/R_386_TLS_LE /i \   || (TYPE) == R_386_TLS_IE \\' \
    -i ./bfd/elfxx-x86.h

make build
cd build

../configure --prefix=/usr       \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib

make tooldir=/usr

make -k check

make tooldir=/usr install

rm -f /usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes}.a

cd /sources
rm -rf ${PKG_BINUTILS%.tar*}

