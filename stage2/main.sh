#!/usr/bin/env bash
# Stage 2
# ~~~~~~~
# This stage roughly covers chapters 3 and 4
# of LFS 11.1, which involves setting up the
# basic directory layout, creating the LFS
# user, and downloading the necessary packages.
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

if [ -z "$(mount | grep $LFS)" ]
then
    echo "ERROR: $LFS_IMG does not appear to be mounted on $LFS."
    exit -1
fi

cd $(dirname $0)

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
mkdir -p $LFS/{boot,home,mnt,opt,srv}
mkdir -p $LFS/etc/{opt,sysconfig}
mkdir -p $LFS/lib/firmware
mkdir -p $LFS/media/{floppy,cdrom}
mkdir -p $LFS/usr/{,local/}{include,src}
mkdir -p $LFS/usr/local/{bin,lib,sbin}
mkdir -p $LFS/usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -p $LFS/usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -p $LFS/usr/{,local/}share/man/man{1..8}
mkdir -p $LFS/var/{cache,local,log,mail,opt,spool}
mkdir -p $LFS/var/lib/{color,misc,locate}
mkdir -p $LFS/{dev,proc,sys,run}
mkdir -p $LFS/home/tester

echo $HOSTNAME > $LFS/etc/hostname

cat > $LFS/etc/hosts <<EOF
127.0.0.1	localhost
127.0.1.1	$HOSTNAME

::1     localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

cp ./inittab ./inputrc ./shells $LFS/etc/
cp ./rc.site $LFS/etc/sysconfig

cat ./fstab | sed "s/LFSUUID/$LFSUUID/;s/FSTYPE/$FSTYPE/" > $LFS/etc/fstab

mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3

touch $LFS/var/log/{btmp,lastlog,faillog,wtmp}

ln -s /run $LFS/var/run
ln -s /run/lock $LFS/var/lock
ln -s /proc/self/mounts $LFS/etc/mtab

install -d -m 0750 $LFS/root
install -d -m 1777 $LFS/tmp $LFS/var/tmp

# group 13 is utmp in the /etc/group file
chgrp 13 $LFS/var/log/lastlog
chmod 664  $LFS/var/log/lastlog
chmod 600  $LFS/var/log/btmp

echo "done."

echo -n "Creating $LFS_USER user... "

if [ -z "$(getent group $LFS_USER)" ]
then
    groupadd $LFS_USER
fi

if ! id $LFS_USER &> /dev/null
then
    useradd -s /bin/bash -g $LFS_USER -m -k /dev/null $LFS_USER
fi

if [ -h $LFS/dev/shm ]; then
  mkdir -p $LFS/$(readlink $LFS/dev/shm)
fi

cp ./{hosts,group,passwd} $LFS/etc

echo "done."

echo -n "Downloading packages to $LFS/sources... "

PACKAGE_URLS=$(cat $PACKAGE_LIST | cut -d"=" -f2)
wget --quiet --directory-prefix $LFS/sources --input-file - <<EOF
$PACKAGE_URLS
EOF

chown -R $LFS_USER:$LFS_USER $LFS/*

echo "done."

