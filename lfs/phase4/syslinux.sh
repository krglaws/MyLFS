# SYSLINUX PHASE 4
patch -Np1 -i ../$(basename $PATCH_SYSLINUX)

make clean
make installer

make install
