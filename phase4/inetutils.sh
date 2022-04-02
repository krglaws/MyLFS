# Inetutils Phase 4
./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install

mv /usr/{,s}bin/ifconfig

