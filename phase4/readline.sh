#!/usr/bin/env bash
# Readline Stage 6
# ~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep READLINE $PACKAGE_LIST)"
PKG_READLINE=$(basename $PKG_READLINE)

tar -xf $PKG_READLINE
cd ${PKG_READLINE%.tar*}

sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install

./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/${PKG_READLINE%.tar*}

make SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install

install -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.1.2

cd /sources
rm -rf ${PKG_READLINE%.tar*}

