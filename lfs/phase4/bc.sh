# Bc Phase 4
CC=gcc ./configure --prefix=/usr -G -O3

make

if $RUN_TESTS
then
    set +e
    make test
    set -e
fi

make install

