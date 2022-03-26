#!/usr/bin/env bash
# efibootmanager Stage 6
# ~~~~~~~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep EFIBOOTMGR $PACKAGE_LIST)"
PKG_EFIBOOTMGR=$(basename $PKG_EFIBOOTMGR)

tar -xf $PKG_EFIBOOTMGR
cd ${PKG_EFIBOOTMGR%.tar*}

sed -e '/extern int efi_set_verbose/d' -i src/efibootmgr.c

sed 's/-Werror//' -i Make.defaults

make EFIDIR=LFS EFI_LOADER=grubx64.efi

make install EFIDIR=LFS

cd /sources
rm -rf ${PKG_EFIBOOTMGR%.tar*}

