# efibootmanager Phase 4
sed -e '/extern int efi_set_verbose/d' -i src/efibootmgr.c

sed 's/-Werror//' -i Make.defaults

make EFIDIR=LFS EFI_LOADER=grubx64.efi

make install EFIDIR=LFS

