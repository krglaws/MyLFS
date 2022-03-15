#!/usr/bin/env bash
# Gawk Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep GAWK $PACKAGE_LIST)"
PKG_GAWK=$(basename $PKG_GAWK)

tar -xf $PKG_GAWK
cd ${PKG_GAWK%.tar*}

sed -i 's/extras//' Makefile.in

./configure --prefix=/usr

make

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/gawk.log
    set -e
fi

make install

mkdir -p /usr/share/doc/gawk-5.1.1
cp doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.1.1

cd /sources
rm -rf ${PKG_GAWK%.tar*}

