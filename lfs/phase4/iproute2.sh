# IPRoute2 Phase 4
sed -i /ARPD/d Makefile
rm -f man/man8/arpd.8

make

make SBINDIR=/usr/sbin install

mkdir -p             /usr/share/doc/iproute2-5.16.0
cp COPYING README* /usr/share/doc/iproute2-5.16.0

