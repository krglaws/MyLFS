# OpenSSL Phase 4
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic

make

if (( RUN_TESTS )); then
    set +e
    HARNESS_JOBS=$(nproc) make test
    set -e
fi

sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install

mv /usr/share/doc/openssl /usr/share/doc/openssl-3.5.2

cp -fr doc/* /usr/share/doc/openssl-3.5.2

