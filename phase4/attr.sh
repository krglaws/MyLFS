# Attr Phase 4
./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.2

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install

