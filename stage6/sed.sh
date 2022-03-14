#!/usr/bin/env bash
# Sed Stage 6
# ~~~~~~~~~~~
set -e

cd /sources

eval "$(grep SED $PACKAGE_LIST)"
PKG_SED=$(basename $PKG_SED)

tar -xf $PKG_SED
cd ${PKG_SED%.tar*}

./configure --prefix=/usr

make
make html

chown -R tester .
su tester -c "PATH=$PATH make check"

make install
install -d -m755 /usr/share/doc/sed-4.8
install -m644 doc/sed.html /usr/share/doc/sed-4.8

cd /sources
rm -rf ${PKG_SED%.tar*}

