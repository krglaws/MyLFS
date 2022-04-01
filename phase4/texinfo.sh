# Texinfo Phase 4
./configure --prefix=/usr

sed -e 's/__attribute_nonnull__/__nonnull/' \
    -i gnulib/lib/malloc/dynarray-skeleton.c

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install

