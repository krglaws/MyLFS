#!/usr/bin/env bash
# Stage 3
# ~~~~~~~
set -e

if [ "$UID" != "0" ]
then
    echo "ERROR: $0 must be run as root."
    exit -1
fi

if [ -z "$LFS" ]
then
    echo "ERROR: $0: Missing config vars."
    exit -1
fi

echo -n "Creating basic directory layout... "

mkdir -p $LFS/sources
chmod a+wt $LFS/sources

mkdir -p $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

for i in bin lib sbin
do
    ln -s usr/$i $LFS/$i
done

case $(uname -m) in
    x86_64) mkdir -p $LFS/lib64;;
esac

mkdir -p $LFS/tools

echo "done."

echo -n "Creating $LFS user... "

if [ -z "$(getent group $LFS_USER)" ]
then
    groupadd $LFS_USER
fi

if ! id $LFS_USER &> /dev/null
then
    useradd -s /bin/bash -g $LFS_USER -m -k /dev/null $LFS_USER
fi

chown $LFS_USER $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools,sources}
case $(uname -m) in
  x86_64) chown $LFS_USER $LFS/lib64 ;;
esac

echo "done."

echo -n "Downloading packages to $LFS/sources... "

PACKAGE_URLS=$(cat $PACKAGE_LIST | cut -d"=" -f2)
wget --quiet --directory-prefix $LFS/sources --input-file - <<EOF
$PACKAGE_URLS
EOF

chown $LFS_USER $LFS/sources/*

echo "done."

