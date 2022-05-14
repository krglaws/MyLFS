# Procps-ng Phase 4
./configure --prefix=/usr                            \
            --docdir=/usr/share/doc/procps-ng-3.3.17 \
            --disable-static                         \
            --disable-kill

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install

