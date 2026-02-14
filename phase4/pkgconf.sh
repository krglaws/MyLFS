# Pkg-config Phase 4
./configure --prefix=/usr              \
            --disable-static           \
            --docdir=/usr/share/doc/pkg-config-2.5.1

make

make install

ln -s pkgconf   /usr/bin/pkg-config
ln -s pkgconf.1 /usr/share/man/man1/pkg-config.1
