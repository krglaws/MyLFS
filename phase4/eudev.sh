# Eudev Phase 4
./configure --prefix=/usr           \
            --bindir=/usr/sbin      \
            --sysconfdir=/etc       \
            --enable-manpages       \
            --disable-static

make

mkdir -p /usr/lib/udev/rules.d
mkdir -p /etc/udev/rules.d

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install

tar -xf ../udev-lfs-20171102.tar.xz
make -f udev-lfs-20171102/Makefile.lfs install

udevadm hwdb --update

