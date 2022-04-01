# Bison Phase 4
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install

