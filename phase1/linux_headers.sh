# Linux API headers Phase 1
make mrproper
make headers

find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr

