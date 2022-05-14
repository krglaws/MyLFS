# Zstd Phase 4
make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make PREFIX=/usr install
rm /usr/lib/libzstd.a

