# mandoc Phase 4
./configure

make mandoc

if $RUN_TESTS
then
    set +e
    make regress
    set -e
fi

install -vm755 mandoc   /usr/bin
install -vm644 mandoc.1 /usr/share/man/man1

