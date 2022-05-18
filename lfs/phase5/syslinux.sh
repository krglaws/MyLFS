# SYSLINUX PHASE 4
patch -Np1 -i ../$(basename $PATCH_SYSLINUX)

make installer

#It is not stable yet
make install
