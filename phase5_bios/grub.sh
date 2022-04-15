./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror

make

make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions

grub-install $LOOP --target i386-pc

cat > /boot/grub/grub.cfg <<EOF
set default=0
set timeout=5

insmod $LFS_FS
set root=(hd0,1)

menuentry "GNU/Linux, Linux 5.16.9-lfs-11.1" {
  search --no-floppy --label $LFSROOTLABEL --set=root
  linux   /boot/vmlinuz-5.16.9-lfs-11.1 root=LABEL=$LFSROOTLABEL ro
}
EOF

