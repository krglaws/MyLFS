# Expat Phase 4
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.4.6

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install

install -m644 doc/*.{html,css} /usr/share/doc/expat-2.4.6

