# Ncurses Phase 4
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --with-pkg-config-libdir=/usr/lib/pkgconfig

make

make DESTDIR=$PWD/dest install
install -m755 dest/usr/lib/libncursesw.so.6.5 /usr/lib
rm dest/usr/lib/libncursesw.so.6.5
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i dest/usr/include/curses.h
cp -av dest/* /

for lib in ncurses form panel menu ; do
    ln -sf lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sf ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
done

ln -sf libncursesw.so /usr/lib/libcurses.so
cp -R doc -T /usr/share/doc/ncurses-6.5-20250809

