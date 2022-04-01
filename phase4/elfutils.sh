# Elfutils Phase 4
./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make -C libelf install
install -m644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a

