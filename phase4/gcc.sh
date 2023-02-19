# GCC Phase 4

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

mkdir build
cd build

../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --disable-multilib       \
             --disable-bootstrap      \
             --with-system-zlib

make

ulimit -s 32768

if $RUN_TESTS
then
    set +e
    chown -Rv tester .
    su tester -c "PATH=$PATH make -k check"
    ../contrib/test_summary
    set -e
fi

make install

chown -R root:root \
    /usr/lib/gcc/*linux-gnu/12.2.0/include{,-fixed}

ln -sr /usr/bin/cpp /usr/lib

ln -sf ../../libexec/gcc/$(gcc -dumpmachine)/12.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/

mkdir -p /usr/share/gdb/auto-load/usr/lib
mv /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

