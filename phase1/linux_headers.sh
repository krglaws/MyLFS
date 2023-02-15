# Linux API headers Phase 1
make mrproper
make headers

find usr/include -type f ! -name '*.h' -delete
cp -r usr/include $LFS/usr

