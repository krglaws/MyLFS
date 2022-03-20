#!/usr/bin/env bash
# mandoc Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep MANDOC $PACKAGE_LIST)"
PKG_MANDOC=$(basename $PKG_MANDOC)

tar -xf $PKG_MANDOC
cd ${PKG_MANDOC%.tar*}

./configure

make mandoc

if $RUN_TESTS
then
    set +e
    make regress &> $TESTLOG_DIR/mandoc.log
    set -e
fi

install -vm755 mandoc   /usr/bin
install -vm644 mandoc.1 /usr/share/man/man1

cd /sources
rm -rf ${PKG_MANDOC%.tar*}

