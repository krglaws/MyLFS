# Expect Phase 4
patch -Np1 -i ../expect-5.45.4-gcc15-1.patch

./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --disable-rpath         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include

make

if $RUN_TESTS
then
    set +e
    make test 
    set -e
fi

make install

ln -sf expect5.45.4/libexpect5.45.4.so /usr/lib

