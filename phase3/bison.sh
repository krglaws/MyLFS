# Bison Phase 3
./configure --prefix=/usr \
            --docdir=/usr/share/doc/${PKG_BISON%.tar*}

make
make install

