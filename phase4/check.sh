# Check Phase 4
./configure --prefix=/usr --disable-static

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make docdir=/usr/share/doc/check-0.15.2 install

