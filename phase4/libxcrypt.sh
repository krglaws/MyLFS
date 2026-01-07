# Libxcrypt Phase 4
./ configure --prefix=/usr                 \
             --enable-hashes=strong,glibc  \
             --enable-obsolete-api=no      \
             --disable-static              \
             --disable-failure-tokens

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install
