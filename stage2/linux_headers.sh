#!/usr/bin/env bash
set -ex

cd $LFS/sources

# linux api headers
tar -xf linux-5.13.12.tar.xz
cd linux-5.13.12

make headers
find usr/include -name '.*' -delete
rm usr/include/Makefile
cp -rv usr/include $LFS/usr

cd $LFS/sources
rm -rf linux-5.13.12
