# Xz Phase 4
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/${PKG_XZ%.tar*}

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install

