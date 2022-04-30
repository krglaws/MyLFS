# Lynx
patch -Np1 -i ../$(basename $PATCH_LYNX)

./configure --prefix=/usr          \
            --sysconfdir=/etc/lynx \
            --datadir=/usr/share/doc/lynx-2.8.9rel.1 \
            --with-zlib            \
            --with-bzlib           \
            --with-ssl             \
            --with-screen=ncursesw \
            --enable-locale-charset
make

make install-full
chgrp -v -R root /usr/share/doc/lynx-2.8.9rel.1/lynx_doc

