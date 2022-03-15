#!/usr/bin/env bash
# GMP Stage 6
# ~~~~~~~~~~~
set -e

cd /sources

eval "$(grep GMP $PACKAGE_LIST)"
PKG_GMP=$(basename $PKG_GMP)

tar -xf $PKG_GMP
cd ${PKG_GMP%.tar*}

./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.2.1

make
make html

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/gmp_test.log
    set -e
fi

PASS_COUNT=$(awk '/# PASS:/{total+=$3} ; END{print total}' /sources/stage6/gmp_test.log)
if [ "$PASS_COUNT" != "" ];
then
    echo "ERROR: GMP tests failed. Check /sources/stage6/gmp_test.log for more info."
    exit -1
fi

make install
make install-html

cd /sources
rm -rf ${PKG_GMP%.tar*}

