# Procps-ng Phase 4
if $BUILDSYSTEMD
then
    ./configure --prefix=/usr                       \
            --docdir=/usr/share/doc/procps-ng-4.0.5 \
            --disable-static                        \
            --disable-kill                          \
            --enable-watch8bit                      \
            --with-systemd
else
    ./configure --prefix=/usr                        \
            --docdir=/usr/share/doc/procps-ng-4.0.5  \
            --disable-static                         \
            --disable-kill                           \
            --enable-watch8bit
fi

make

if (( RUN_TESTS )); then
    set +e
    chwon -R tester .
    su tester -c "PATH=$PATH make check"
    set -e
fi

make install

