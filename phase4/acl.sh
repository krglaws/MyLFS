# Acl Phase 4
./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/usr/share/doc/acl-2.3.2

make

if (( RUN_TESTS )); then
    set -e
    make check
    set +e
fi

make install

