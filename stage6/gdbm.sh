#!/usr/bin/env bash
# GDBM Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep GDBM $PACKAGE_LIST)"
PKG_GDBM=$(basename $PKG_GDBM)

tar -xf $PKG_GDBM
cd ${PKG_GDBM%.tar*}

./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat

make

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/gdbm.log
    set -e
fi

make install

cd /sources
rm -rf ${PKG_GDBM%.tar*}

