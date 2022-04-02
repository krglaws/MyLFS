# Libcap Phase 4
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib

if $RUN_TESTS
then
    set +e
    make test
    set -e
fi

make prefix=/usr lib=lib install

