#!/usr/bin/env bash
# ncurses Stage 4
# ~~~~~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep NCURSES $PACKAGE_LIST)"
PKG_NCURSES=$(basename $PKG_NCURSES)

tar -xf $PKG_NCURSES
cd ${PKG_NCURSES%.tar*}

sed -i s/mawk// configure

mkdir build
pushd build
../configure
make -C include
make -C progs tic
popd

./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-debug              \
            --without-ada                \
            --without-normal             \
            --disable-stripping          \
            --enable-widec

make
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so

cd $LFS/sources
rm -rf ${PKG_NCURSES%.tar*}

