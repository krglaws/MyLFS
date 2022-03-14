#!/usr/bin/env bash
# Bash Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep BASH $PACKAGE_LIST)"
PKG_BASH=$(basename $PKG_BASH)

tar -xf $PKG_BASH
cd ${PKG_BASH%.tar*}

./configure --prefix=/usr                      \
            --docdir=/usr/share/doc/bash-5.1.16 \
            --without-bash-malloc              \
            --with-installed-readline

make

chown -R tester .

su -s /usr/bin/expect tester << EOF
set timeout -1
spawn make tests
expect eof
lassign [wait] _ _ _ value
exit $value
EOF

make install

cd /sources
rm -rf ${PKG_BASH%.tar*}

