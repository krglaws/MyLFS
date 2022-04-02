# MPFR Phase 4
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.1.0

make
make html

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install
make install-html

