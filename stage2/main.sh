#!/usr/bin/bash
set -e

if [ "$UID" != "0" ]
then
    echo "ERROR: $0 must be executed as root."
    exit -1
fi

if [ -z "$LFS" -o -z "$LFS_USER" ]
then
    echo "ERROR: Missing config vars. Be sure to source config.sh before running this script."
    exit -1
fi

echo "Creating basic directory layout..."
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
echo "Done."

if [ -z "$(getent group $LFS_USER)" ]
then
    echo "Creating group ${LFS_USER}..."
    groupadd $LFS_USER
    echo "Done."
fi

if ! id $LFS_USER
then
    echo "Creating user ${LFS_USER}..."
    useradd -s /bin/bash -g $LFS_USER -m -k /dev/null $LFS_USER
    echo "Done."
fi

echo "Giving user $LFS_USER directory ownership in $LFS..."
chown $LFS_USER $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools,sources}
case $(uname -m) in
  x86_64) chown $LFS_USER $LFS/lib64 ;;
esac
echo "Done."

