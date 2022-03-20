#!/usr/bin/env bash
# GRUB Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep GRUB $PACKAGE_LIST)"
PKG_GRUB=$(basename $PKG_GRUB)

tar -xf $PKG_GRUB
cd ${PKG_GRUB%.tar*}

mkdir -pv /usr/share/fonts/unifont &&
gunzip -c ../unifont-14.0.01.pcf.gz > /usr/share/fonts/unifont/unifont.pcf

unset {C,CPP,CXX,LD}FLAGS

./configure --prefix=/usr        \
            --sysconfdir=/etc    \
            --disable-efiemu     \
            --with-platform=efi  \
            --target=x86_64      \
            --disable-werror     \
#           --enable-grub-mkfont (uncomment if using FreeType)

unset TARGET_CC

make

make install

mv /etc/bash_completion.d/grub /usr/share/bash-completion/completions

GRUB_OUTPUT=$(grub-install --bootloader-id=LFS --recheck)
if ! echo $GRUB_OUTPUT | grep "No error reported"
then
    echo "An error occured while installing GRUB:"
    echo $GRUB_OUTPUT
    exit -1
fi

cd /sources
rm -rf ${PKG_GRUB%.tar*}

