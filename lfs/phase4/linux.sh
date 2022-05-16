# LINUX Phase 4

function config_on {
    local UNCOMMENTED="^${1}=.*\$"
    local COMMENTED="^# ${1} .*\$"
    if [ -z "$(grep ${1} ./.config)" ]
    then
        echo "${1}=y" >> ./.config
        return
    fi
    sed -E -i "s/${UNCOMMENTED}|${COMMENTED}/${1}=y/" ./.config
}

function config_off {
    sed -i "s/^${1}=.*$/# $1 is not set/" ./.config
}

CONFIGFILE=config-$KERNELVERS
make mrproper

# if kernel config not provided, use default architecture config
make defconfig

if [ -f /boot/$CONFIGFILE ]
then
    cp /boot/$CONFIGFILE ./.config
else
    config_off CONFIG_IKHEADERS
    config_on  CONFIG_FB
    config_off CONFIG_UEVENT_HELPER
    config_on  CONFIG_DEVTMPFS
    config_on  CONFIG_MODULES
    #... more need to add
fi

# This is broken for now
make

make modules_install

cp ./.config /boot/$CONFIGFILE

cp arch/x86_64/boot/bzImage /boot/vmlinuz-$KERNELVERS-lfs-$LFS_VERSION

cp System.map /boot/System.map-$KERNELVERS

install -d /usr/share/doc/linux-$KERNELVERS
cp -r Documentation/* /usr/share/doc/linux-$KERNELVERS

