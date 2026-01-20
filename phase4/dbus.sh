# D-Bus Phase 4
mkdir build
cd build

meson setup --prefix=/usr --buildtype=release --wrap-mode=nofallback ..

ninja

ninja test

ninja install

ln -sf /etc/machine-id /var/lib/dbus

