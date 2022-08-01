# p11kit

sed '20,$ d' -i trust/trust-extract-compat

cat >> trust/trust-extract-compat << "EOF"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications

# Update trust stores
/usr/sbin/make-ca -r
EOF

mkdir p11-build
cd p11-build

meson --prefix=/usr \
      --buildtype=release \
      -Dtrust_paths=/etc/pki/anchors

ninja

if $RUN_TESTS
then
    set +e
    ninja test
    set -e
fi

ninja install

ln -sf /usr/libexec/p11-kit/trust-extract-compat \
       /usr/bin/update-ca-certificates

ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so

