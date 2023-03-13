# Kbd Phase 4
patch -Np1 -i ../$(basename $PATCH_KBD)

sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

./configure --prefix=/usr --disable-vlock

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install

mkdir -pv           /usr/share/doc/kbd-2.5.1
cp -R -v docs/doc/* /usr/share/doc/kbd-2.5.1

