# Less Phase 4
./configure --prefix=/usr --sysconfdir=/etc

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install

