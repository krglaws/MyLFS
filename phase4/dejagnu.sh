# DejaGNU Phase 4
mkdir build
cd       build

../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi

make install
install -dm755  /usr/share/doc/dejagnu-1.6.3
install -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3

if $RUN_TESTS
then
    set +e
    make check
    set -e
fi

