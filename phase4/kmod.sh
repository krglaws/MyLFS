# Kmod Phase 4
./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --with-openssl         \
            --with-xz              \
            --with-zstd            \
            --with-zlib

make

make install

for target in depmod insmod modinfo modprobe rmmod; do
  ln -sf ../bin/kmod /usr/sbin/$target
done

ln -sf kmod /usr/bin/lsmod

