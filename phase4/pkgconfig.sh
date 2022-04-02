# Pkg-config Phase 4
./configure --prefix=/usr              \
            --with-internal-glib       \
            --disable-host-tool        \
            --docdir=/usr/share/doc/pkg-config-0.29.2

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install

