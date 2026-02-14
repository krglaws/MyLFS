patch -Np1 -i ../$(basename $PATCH_SYSVINIT)

make

make install
