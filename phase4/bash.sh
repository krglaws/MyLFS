# Bash Phase 4
./configure --prefix=/usr                      \
            --without-bash-malloc              \
            --docdir=/usr/share/doc/bash-5.3   \
            --with-installed-readline

make


if (( RUN_TESTS )); then
    set +e
chown -R tester .
LC_ALL=C.UTF-8 su -s /usr/bin/expect tester << "EOF"
set timeout -1
spawn make tests
expect eof
lassign [wait] _ _ _ value
exit $value
EOF
    set -e
fi

make install

