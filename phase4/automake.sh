# Automake Phase 4
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.18.1

make

if $RUN_TESTS
then
    set +e
    make -j$(($(nproc)>4?$(nproc):4)) check
    set -e
fi

make install

