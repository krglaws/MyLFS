# IPRoute2 Phase 4
sed -i /ARPD/d Makefile
rm -f man/man8/arpd.8

make NETNS_RUN_DIR=/run/netns

make SBINDIR=/usr/sbin install

install -Dm644 COPYING README* -t /usr/share/doc/iproute2-6.16.0

