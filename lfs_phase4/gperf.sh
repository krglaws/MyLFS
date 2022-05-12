# Gperf Phase 4
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1

make

if $RUN_TESTS
then
    set +e
    make -j1 check
    set -e
fi

make install

