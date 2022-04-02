# LINUX Phase 4
CONFIGFILE=config-$KERNELVERS
make mrproper

if [ -f /boot/$CONFIGFILE ]
then
    cp /boot/$CONFIGFILE ./.config
else
    # if kernel config not provided, use default architecture config
    make defconfig
fi

make

make modules_install

cp ./.config /boot/$CONFIGFILE

cp arch/x86_64/boot/bzImage /boot/vmlinuz-$KERNELVERS-lfs-11.1

cp System.map /boot/System.map-$KERNELVERS

install -d /usr/share/doc/linux-$KERNELVERS
cp -r Documentation/* /usr/share/doc/linux-$KERNELVERS

