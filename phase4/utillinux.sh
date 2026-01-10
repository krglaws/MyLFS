# Util-linux Phase 4
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
            --bindir=/usr/bin    \
            --libdir=/usr/lib    \
            --runstatedir=/run   \
            --sbindir=/usr/sbin  \
            --docdir=/usr/share/doc/util-linux-2.41.1 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            --disable-liblastlog2

make

if $RUN_TESTS
then
    set +e
    touch /etc/fstab
    chown -Rv tester .
    su tester -c "make -k check"
    set -e
fi

make install

