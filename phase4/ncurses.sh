# Ncurses Phase 4
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --enable-widec          \
            --with-pkg-config-libdir=/usr/lib/pkgconfig

make

make DESTDIR=$PWD/dest install
install -m755 dest/usr/lib/libncursesw.so.6.3 /usr/lib
rm dest/usr/lib/libncursesw.so.6.3
cp -av dest/* /

for lib in ncurses form panel menu ; do
    rm -f                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sf ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done

rm -f                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sf libncurses.so      /usr/lib/libcurses.so

mkdir -p      /usr/share/doc/ncurses-6.3
cp -R doc/* /usr/share/doc/ncurses-6.3

