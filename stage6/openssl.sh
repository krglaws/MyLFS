#!/usr/bin/env bash
# OpenSSL Stage 6
# ~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep OPENSSL $PACKAGE_LIST)"
PKG_OPENSSL=$(basename $PKG_OPENSSL)

tar -xf $PKG_OPENSSL
cd ${PKG_OPENSSL%.tar*}

./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic

make

if $RUN_TESTS
then
    set +e
    make test &> $TESTLOG_DIR/openssl.log
    set -e
fi

sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install

mv /usr/share/doc/openssl /usr/share/doc/openssl-3.0.1

cp -fr doc/* /usr/share/doc/openssl-3.0.1

cd /sources
rm -rf ${PKG_OPENSSL%.tar*}

