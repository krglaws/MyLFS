# LINUX Phase 4
# section 10.3
CONFIGFILE=config-$LFS_KERNEL_VERSION

make mrproper

if [[ -f /boot/$CONFIGFILE ]]; then
    cp /boot/$CONFIGFILE ./.config
    make olddefconfig
else
    make defconfig
    ./scripts/config --disable CONFIG_WERROR
    ./scripts/config --enable  CONFIG_PSI
    ./scripts/config --disable CONFIG_PSI_DEFAULT_DISABLE
    ./scripts/config --disable CONFIG_IKHEADERS
    ./scripts/config --enable  CONFIG_CGROUPS
    ./scripts/config --enable  CONFIG_MEMCG
    (( BUILDSYSTEMD )) && ./scripts/config --enable  CONFIG_CGROUP_SCHED
    (( BUILDSYSTEMD )) && ./scripts/config --disable CONFIG_RT_GROUP_SCHED
    ./scripts/config --disable CONFIG_EXPERT
    ./scripts/config --enable  CONFIG_RELOCATABLE
    ./scripts/config --enable  CONFIG_RANDOMIZE_BASE
    ./scripts/config --enable  CONFIG_STACKPROTECTOR
    ./scripts/config --enable  CONFIG_STACKPROTECTOR_STRONG
    (( BUILDSYSTEMD )) && ./scripts/config --enable  CONFIG_NET
    (( BUILDSYSTEMD )) && ./scripts/config --enable  CONFIG_INET
    (( BUILDSYSTEMD )) && ./scripts/config --enable  CONFIG_IPV6
    ./scripts/config --disable CONFIG_UEVENT_HELPER
    ./scripts/config --enable  CONFIG_DEVTMPFS
    ./scripts/config --enable  CONFIG_DEVTMPFS_MOUNT
    (( BUILDSYSTEMD )) && ./scripts/config --enable  CONFIG_FW_LOADER
    (( BUILDSYSTEMD )) && ./scripts/config --disable CONFIG_FW_LOADER_USER_HELPER
    (( BUILDSYSTEMD )) && ./scripts/config --enable  CONFIG_DMIID
    ./scripts/config --enable  CONFIG_SYSFB_SIMPLEFB
    ./scripts/config --enable  CONFIG_DRM
    ./scripts/config --enable  CONFIG_DRM_PANIC
    ./scripts/config --enable  CONFIG_DRM_PANIC_SCREEN
    ./scripts/config --enable  CONFIG_DRM_FBDEV_EMULATION
    ./scripts/config --enable  CONFIG_DRM_SIMPLEDRM
    ./scripts/config --enable  CONFIG_FRAMEBUFFER_CONSOLE
    (( BUILDSYSTEMD )) && ./scripts/config --enable  CONFIG_INOTIFY_USER
    (( BUILDSYSTEMD )) && ./scripts/config --enable  CONFIG_TMPFS
    (( BUILDSYSTEMD )) && ./scripts/config --enable  CONFIG_TMPFS_POSIX_ACL
    ./scripts/config --enable  CONFIG_X86_X2APIC
    ./scripts/config --enable  CONFIG_PCI
    ./scripts/config --enable  CONFIG_PCI_MSI
    ./scripts/config --enable  CONFIG_IOMMU_SUPPORT
    ./scripts/config --enable  CONFIG_IRQ_REMAP
    ./scripts/config --enable  CONFIG_BLK_DEV_NVME
    make olddefconfig
fi

make

make modules_install

cp arch/x86/boot/bzImage /boot/vmlinuz-${LFS_KERNEL_VERSION}-lfs-${LFS_VERSION}${LFS_KERNEL_SUFFIX}

cp System.map /boot/System.map-${LFS_KERNEL_VERSION}

cp .config /boot/$CONFIGFILE

cp -r Documentation -T /usr/share/doc/linux-${LFS_KERNEL_VERSION}

install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF
