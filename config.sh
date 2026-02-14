# shellcheck disable=SC2034

# #######################
# LFS Build Configuration
# ~~~~~~~~~~~~~~~~~~~~~~~

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ARCH=$(uname -m)

set +h
umask 022

# exported vars are used by one or more of:
# 1) the scripts in the chroot env
# 2) make or other build tools
# 3) in the template files
export LC_ALL=POSIX
export LFS_VERSION=12.4
export LFS_CODENAME=lfs  # change this to whatever you want
export LFS_KERNEL_VERSION=6.16.1
export LFS_TGT=$ARCH-lfs-linux-gnu
export LFS_ROOT_LABEL=LFSROOT
export LFS_FS_TYPE=ext4
export LFS_ZONEINFO=America/New_York
export MAKEFLAGS=${MAKEFLAGS:--j8}
export ROOT_PASSWD=${ROOT_PASSWD:-password} # change this to whatever you want
export LFS_HOSTNAME=${LFS_HOSTNAME:-lfs}  # change this to whatever you want

# these are configs used by mylfs.sh, but are not
# likely to be something you will want to change
export LFS=$SCRIPT_DIR/mnt/lfs
export CONFIG_SITE=$LFS/usr/share/config.site
export PATH=/usr/bin:/usr/sbin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
LFS_IMG=$SCRIPT_DIR/lfs.img
LFS_IMG_SIZE=$((10*1024*1024*1024)) # 10 GiB
INSTALL_MOUNT=$SCRIPT_DIR/mnt/install
LFS_PACKAGE_LIST=$SCRIPT_DIR/packages.sh
LFS_PACKAGE_DIR=$SCRIPT_DIR/packages

################################################
# the following configs are overrideable via the
# mylfs.sh command line inteface.
VERBOSITY=1  # how much logger output to show 0 == no output
SHOWBUILDOUTPUT=0 # echo all build commands and their outputs to terminal
ONEOFF=0  # only build package specified by STARTPHASE + STARTPKG
EXTENSIONDIR=  # path to extension directory (see ./example_extension)
STARTPKG=  # package to start build at
ENDPHASE=  # phase to halt build at
ENDPKG=  # package to halt build at
KERNELCONFIG=  # path to kernel config
DROPSHELL=0  # run interactive bash session instead of build script
SKIPDOWNLOAD=0 # skip the --download step which often preceeds other operations
SKIPINIT=0 # skip the --init step which often preceeds other operations
export RUN_TESTS=0

# used for the systemd build
export BUILDSYSTEMD=0
KERNEL_SUFFIX=$( ((BUILDSYSTEMD)) && echo -systemd || echo "" )
export LFS_KERNEL_SUFFIX=$KERNEL_SUFFIX

# only one of these can be "set" at a time
BUILDALL=0  # build everything from the beginning
CHECKDEPS=0  # check the build requirements
DOWNLOAD=0  # download packages
INIT=0  # create (mostly) empty image file
STARTPHASE=  # phase to start build at
MOUNT=0  # mount the image file onto $LFS
UNMOUNT=0  # opposite of MOUNT
INSTALLTARGET=  # path to device file to install LFS on (please don't nuke your hard drive)
CLEAN=0  # delete $LFS_IMG and files under $SCRIPT_DIR/logs

##############
# fdisk script -- you probably don't want to change this
FDISK_INSTR="
o       # create DOS partition table
n       # new partition
        # default partition type (primary)
        # default partition number (1)
        # default partition start
        # default partition end (max)
y       # confirm overwrite (noop if not prompted)
w       # write to device and quit
"

################################################
# the remaining config vars contain the contents
# of various files. *_SYSTEMD means it is only used
# for the systemd build, and *_SYSVINIT for the default
# sysv init build.
ETC_PASSWD_SYSVINIT="\
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
tester:x:101:101::/home/tester:/bin/bash"

ETC_PASSWD_SYSTEMD="\
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
tester:x:101:101::/home/tester:/bin/bash"

ETC_GROUP_SYSVINIT="\
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
tester:x:101:"

ETC_GROUP_SYSTEMD="\
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
wheel:x:97:
users:x:999:
nogroup:x:65534:
tester:x:101:"

ETC_SYSTEMD_NETWORK="\
[Match]
Name=eth0

[Network]
Address=192.168.0.2/24
Gateway=192.168.0.1"

ETC_FSTAB_SYSVINIT="\
LABEL=$LFS_ROOT_LABEL   /              $LFS_FS_TYPE     defaults            1     1
proc            /proc          proc     nosuid,noexec,nodev 0     0
sysfs           /sys           sysfs    nosuid,noexec,nodev 0     0
devpts          /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs           /run           tmpfs    defaults            0     0
devtmpfs        /dev           devtmpfs mode=0755,nosuid    0     0
tmpfs           /dev/shm       tmpfs    nosuid,nodev        0     0
cgroup2         /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0     0
"

ETC_FSTAB_SYSTEMD="\
LABEL=$LFS_ROOT_LABEL   /          $LFS_FS_TYPE   defaults              1   1
"

ETC_SYSTEMD_VCONSOLE="FONT=Lat2-Terminus16"

ETC_LOCALECONF_SYSTEMD="LANG=en_US.UTF-8"
