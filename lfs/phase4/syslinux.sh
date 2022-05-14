# SYSLINUX PHASE 4
patch -Np1 -i ../$(basename $PATCH_SYSLINUX)

make installer

make install
