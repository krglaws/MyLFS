# D-Bus Phase 4
mkdir build
cd build

meson setup --prefix=/usr --buildtype=release --wrap-mode=nofallback ..

ninja

if $RUN_TESTS
then
    set -e
    ninja test
    set +e
fi

ninja install

ln -sf /etc/machine-id /var/lib/dbus

