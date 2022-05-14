# Libffi Phase 4
./configure --prefix=/usr          \
            --disable-static       \
            --with-gcc-arch=native \
            --disable-exec-static-tramp

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install

