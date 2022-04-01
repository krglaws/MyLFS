# Flex Phase 4
./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static

make

if $RUN_TESTS
then
    set +e
    make check 
    set -e
fi

make install

ln -s flex /usr/bin/lex

