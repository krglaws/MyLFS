# Gawk Phase 4
sed -i 's/extras//' Makefile.in

./configure --prefix=/usr

make

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

make install

mkdir -p /usr/share/doc/gawk-5.1.1
cp doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.1.1

