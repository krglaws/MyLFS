#!/usr/bin/env bash
# E2fsprogs Stage 6
# ~~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep E2FSPROGS $PACKAGE_LIST)"
PKG_E2FSPROGS=$(basename $PKG_E2FSPROGS)

tar -xf $PKG_E2FSPROGS
cd ${PKG_E2FSPROGS%.tar*}

mkdir -v build
cd       build

../configure --prefix=/usr           \
             --sysconfdir=/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck

make

make check

make install

rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a

gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info

makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

cd /sources
rm -rf ${PKG_E2FSPROGS%.tar*}

