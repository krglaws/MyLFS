# Autoconf Phase 4
./configure --prefix=/usr

make

if $RUN_TESTS
then
    set +e
    make check TESTSUITEFLAGS=-j4
    set -e
fi

make install 

