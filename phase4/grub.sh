# Grub Phase 4
echo depends bli part_gpt > grub-core/extra_deps.lst

./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror

make

make install
mv /etc/bash_completion.d/grub /usr/share/bash-completion/completions

# TODO not sure if this is necessary yet
#grub-install $LOOP --target i386-pc
