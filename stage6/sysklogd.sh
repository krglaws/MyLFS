#!/usr/bin/env bash
# Sysklogd Stage 6
# ~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep SYSKLOGD $PACKAGE_LIST)"
PKG_SYSKLOGD=$(basename $PKG_SYSKLOGD)

tar -xf $PKG_SYSKLOGD
cd ${PKG_SYSKLOGD%.tar*}

sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
sed -i 's/union wait/int/' syslogd.c

make

make BINDIR=/sbin install

cd /sources
rm -rf ${PKG_SYSKLOGD%.tar*}

