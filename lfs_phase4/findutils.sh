# Findutils Phase 4
case $(uname -m) in
    i?86)   TIME_T_32_BIT_OK=yes ./configure --prefix=/usr --localstatedir=/var/lib/locate ;;
    x86_64) ./configure --prefix=/usr --localstatedir=/var/lib/locate ;;
esac

make

if $RUN_TESTS
then
    set +e
    chown -R tester .
    su tester -c "PATH=$PATH make check"
    set -e
fi

make install

