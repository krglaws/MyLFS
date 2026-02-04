# LINUX Phase 4
# section 10.3
CONFIGFILE=config-$LFS_KERNEL_VERSION

make mrproper

if [ -f /boot/$CONFIGFILE ]
then
    cp /boot/$CONFIGFILE ./.config
    make olddefconfig
else
    make defconfig
    # ./scripts/config --enable CONFIG_*
    # ./scripts/config --modue CONFIG_*
    # ./scripts/config --disable CONFIG_*
    make olddefconfig
fi

make

make modules_install

cp -i arch/x86/boot/bzImage /boot/vmlinuz-${LFS_KERNEL_VERSION}-lfs-${LFS_VERSION}${LFS_KERNEL_SUFFIX}

cp System.map /boot/System.map-${LFS_KERNEL_VERSION}

cp -i .config /boot/$CONFIGFILE

cp -r Documentation -T /usr/share/doc/linux-${LFS_KERNEL_VERSION}

install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF
