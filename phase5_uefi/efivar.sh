# efivar Phase 4
sed '/prep :/a\\ttouch prep' -i src/Makefile

make

make install LIBDIR=/usr/lib

