# Kmod Phase 4
mkdir -p build
cd       build

meson setup --prefix=/usr ..       \
            --buildtype=release    \
            -D manpages=false

ninja

ninja install

