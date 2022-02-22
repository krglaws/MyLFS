#!/usr/bin/env bash
set -e +h

# LFS workspace for building packages
mkdir -p $LFS/sources

# basic LFS file system layout
mkdir -p $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin;
do
    if [ ! -L $LFS/$i ]
    then
        ln -s usr/$i $LFS/$i
    fi
done
case $(uname -m) in
    x86_64)
    mkdir -p $LFS/lib64;;
esac

# temporary cross compiler binaries go here
mkdir -p $LFS/tools


umask 022
