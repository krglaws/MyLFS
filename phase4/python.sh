# Python Phase 4
./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --with-system-ffi    \
            --enable-optimizations

make

make install

install -dm755 /usr/share/doc/python-3.10.6/html

cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF

tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.10.6/html \
    -xvf ../$(basename $PKG_PYTHONDOCS)

