# GRUB Phase 4
mkdir -p /usr/share/fonts/unifont
gunzip -c ../$(basename $PKG_UNIFONT) > /usr/share/fonts/unifont/unifont.pcf

unset {C,CPP,CXX,LD}FLAGS

./configure --prefix=/usr        \
            --sysconfdir=/etc    \
            --disable-efiemu     \
            --with-platform=efi  \
            --target=x86_64      \
            --disable-werror     
#           --enable-grub-mkfont (uncomment if using FreeType)

unset TARGET_CC

make

make install

mv /etc/bash_completion.d/grub /usr/share/bash-completion/completions

GRUB_OUTPUT=$(grub-install --bootloader-id=LFS --recheck)
if [ -n "$(echo $GRUB_OUTPUT | grep "No error reported")" ]
then
    echo "An error occured while installing GRUB:"
    echo $GRUB_OUTPUT
    exit -1
fi

cat > /boot/grub/grub.cfg <<EOF
set default=0
set timeout=5

insmod part_gpt
insmod $LFS_FS
set root=(hd0,2)

if loadfont /boot/grub/fonts/unicode.pf2; then
  set gfxmode=auto
  insmod all_video
  terminal_output gfxterm
fi

menuentry "GNU/Linux, Linux 5.16.9-lfs-11.1"  {
  search --no-floppy --label $LFSROOTLABEL --set=root
  linux   /boot/vmlinuz-5.16.9-lfs-11.1 root=LABEL=$LFSROOTLABEL ro
}

menuentry "Firmware Setup" {
  fwsetup
}
EOF

