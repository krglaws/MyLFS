# Groff Phase 4
PAGE=letter ./configure --prefix=/usr

make 

if (( RUN_TESTS )); then
    set +e
    make check
    set -e
fi

make install

