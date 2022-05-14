# Binutils Phase 4
patch -Np1 -i ../$(basename $PATCH_BINUTILS)

sed -e '/R_386_TLS_LE /i \   || (TYPE) == R_386_TLS_IE \\' \
    -i ./bfd/elfxx-x86.h

mkdir build
cd build

../configure --prefix=/usr       \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib

make tooldir=/usr

if $RUN_TESTS
then
    set +e
    make -k check 
    set -e
fi

make tooldir=/usr install

rm -f /usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes}.a

