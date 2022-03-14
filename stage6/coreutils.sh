#!/usr/bin/env bash
# Coreutils Stage 6
# ~~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep COREUTILS $PACKAGE_LIST)"
PKG_COREUTILS=$(basename $PKG_COREUTILS)
PATCH_COREUTILS=$(basename $PATCH_COREUTILS)
PATCH_COREUTILS_CHMOD=$(basename $PATCH_COREUTILS_CHMOD)

tar -xf $PKG_COREUTILS
cd ${PKG_COREUTILS%.tar*}

patch -Np1 -i ../$PATCH_COREUTILS
patch -Np1 -i ../$PATCH_COREUTILS_CHMOD

autoreconf -fi
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime

make

make NON_ROOT_USERNAME=tester check-root

echo "dummy:x:102:tester" >> /etc/group

chown -R tester . 

su tester -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"

sed -i '/dummy/d' /etc/group

make install

mv /usr/bin/chroot /usr/sbin
mv /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8

cd /sources
rm -rf ${PKG_COREUTILS%.tar*}

