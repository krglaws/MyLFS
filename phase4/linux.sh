# LINUX Phase 4
# section 10.3
CONFIGFILE=config-$KERNELVERS

make mrproper

if [ -f /boot/$CONFIGFILE ]
then
    cp /boot/$CONFIGFILE ./.config
    make olddefconfig
else
    make defconfig
fi

make

make modules_install

cp -i arch/x86/boot/bzImage /boot/vmlinuz-$KERNELVERS-lfs-$LFS_VERSION-systemd

cp System.map /boot/System.map-$KERNELVERS

cp -i .config /boot/$CONFIGFILE

cp -r Documentation -T /usr/share/doc/linux-$KERNELVERS

