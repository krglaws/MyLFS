# libtasn1

./configure --prefix=/usr --disable-static
make

if $RUN_TESTS
then
    make check
fi

make install

make -C doc/reference install-data-local
