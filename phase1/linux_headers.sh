# Linux API headers Phase 1
make mrproper
make headers

find usr/include -name '.*' -delete
rm usr/include/Makefile
cp -r usr/include $LFS/usr

