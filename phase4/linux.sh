# LINUX Phase 4

function config_on {
    local UNCOMMENTED="^${1}=.*\$"
    local COMMENTED="^# ${1} .*\$"
    sed -E -i "s/${UCOMMENTED}|${COMMENTED}/${1}=y/" ./.config
}

function config_off {
    sed -i "s/^${1}=.*$//" ./.config
}

CONFIGFILE=config-$KERNELVERS
make mrproper

if [ -f /boot/$CONFIGFILE ]
then
    cp /boot/$CONFIGFILE ./.config
else
    # if kernel config not provided, use default architecture config
    make defconfig

    config_off CONFIG_IKHEADERS
    config_on  CONFIG_FB
    config_off CONFIG_UEVENT_HELPER
    config_on  CONFIG_DEVTMPFS
    config_on  CONFIG_MODULES
fi

make

make modules_install

cp ./.config /boot/$CONFIGFILE

cp arch/x86_64/boot/bzImage /boot/vmlinuz-$KERNELVERS-lfs-11.1

cp System.map /boot/System.map-$KERNELVERS

install -d /usr/share/doc/linux-$KERNELVERS
cp -r Documentation/* /usr/share/doc/linux-$KERNELVERS

