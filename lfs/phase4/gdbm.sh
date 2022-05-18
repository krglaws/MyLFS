# GDBM Phase 4
./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install

