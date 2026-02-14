# Grep Phase 4
sed -i "s/echo/#echo/" src/egrep.sh
./configure --prefix=/usr

make

if (( RUN_TESTS )); then
    set +e
    make check
    set -e
fi

make install

