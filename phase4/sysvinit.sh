# Sysvinit Phase 4
patch -Np1 -i ../$(basename $PATCH_SYSVINIT)

make

make install

