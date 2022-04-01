# GMP Phase 4
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.2.1

make
make html

if $RUN_TESTS
then
    set +e
    make check 
    set -e
fi

#PASS_COUNT=$(awk '/# PASS:/{total+=$3} ; END{print total}' $TESTLOG_DIR/gmp.log)
#if [ "$PASS_COUNT" != "" ];
#then
#    echo "ERROR: GMP tests failed. Check /sources/stage6/gmp_test.log for more info."
#    exit -1
#fi

make install
make install-html

