# Intltool Phase 4
sed -i 's:\\\${:\\\$\\{:' intltool-update.in

./configure --prefix=/usr

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install
install -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO

