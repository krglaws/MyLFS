# IPRoute2 Phase 4
sed -i /ARPD/d Makefile
rm -f man/man8/arpd.8

make NETNS_RUN_DIR=/run/netns

make SBINDIR=/usr/sbin install

mkdir -p             /usr/share/doc/iproute2-5.19.0
cp COPYING README* /usr/share/doc/iproute2-5.19.0

