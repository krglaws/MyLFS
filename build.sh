#!/usr/bin/env bash
set -e

if [ $UID -ne 0 ]
then
    echo "ERROR: This script must be run as root."
    exit 1
fi

LFS_VERSION=11.1

# #########
# Functions
# ~~~~~~~~~

function usage {
    echo -e "Welcome to MyLFS.\n" \
         "    options: \n" \
         "        -e|--check          Outputs LFS dependency version information, then exits.\n" \
         "                            It is recommended that you run this before proceeding\n" \
         "                            with the rest of the build.\n" \
         "\n" \
         "        -p|--start-phase\n" \
         "        -a|--start-package  Select a phase and optionally a package\n" \
         "                            within that phase to start building from.\n" \
         "                            These options are only available if the preceeding\n" \
         "                            phases have been completed. They should really only\n" \
         "                            be used when something broke during a build, and you\n" \
         "                            don't want to start from the beginning again.\n" \
         "\n" \
         "        -o|--one-off        Only build the specified phase/package.\n" \
         "\n" \
         "        -k|--kernel-config  Optional path to kernel config file to use during linux\n" \
         "                            build.\n" \
         "\n" \
         "        -m|--mount\n" \
         "        -u|--umount         These options will mount or unmount the disk image to the\n" \
         "                            filesystem, and then exit the script immediately.\n" \
         "                            You should be sure to unmount prior to running any part of\n" \
         "                            the build, since the image will be automatically mounted\n" \
         "                            and then unmounted at the end.\n" \
         "\n" \
         "        -c|--clean          This will unmount and delete the image, and clear the\n" \
         "                            logs.\n" \
         "\n" \
         "        -v|--version        Print the LFS version this build is based on.\n" \
         "\n" \
         "        -h|--help           Show this message."
}

function check_dependency {
    local PROG=$1
    local MINVERS=$2
    local MAXVERS=$([ -n "$3" ] && echo $3 || echo "none")

    if ! command -v $PROG > /dev/null
    then
        echo "ERROR: '$PROG' not found"
        return 1
    fi

    echo -e "$PROG:\n" \
            "  Minimum: $MINVERS, Maximum: $MAXVERS\n" \
            "  You have: $($PROG --version | head -n 1)"

    return 0
}

function kernel_vers {
    cat /proc/version | head -n1
}

function perl_vers {
    perl -V:version
}

function check_dependencies {
    EXIT_STATUS=0

    if ! check_dependency bash        3.2        ; then EXIT_STATUS=1; fi
    if ! check_dependency ld          2.13.1 2.38; then EXIT_STATUS=1; fi  # binutils
    if ! check_dependency bison       2.7        ; then EXIT_STATUS=1; fi
    if ! check_dependency chown       6.9        ; then EXIT_STATUS=1; fi  # coreutils
    if ! check_dependency diff        2.8.1      ; then EXIT_STATUS=1; fi
    if ! check_dependency find        4.2.31     ; then EXIT_STATUS=1; fi
    if ! check_dependency gawk        4.0.1      ; then EXIT_STATUS=1; fi
    if ! check_dependency gcc         4.8 11.2.0 ; then EXIT_STATUS=1; fi
    if ! check_dependency g++         4.8 11.2.0 ; then EXIT_STATUS=1; fi
    if ! check_dependency grep        2.5.1a     ; then EXIT_STATUS=1; fi
    if ! check_dependency gzip        1.3.12     ; then EXIT_STATUS=1; fi
    if ! check_dependency m4          1.4.10     ; then EXIT_STATUS=1; fi
    if ! check_dependency make        4.0        ; then EXIT_STATUS=1; fi
    if ! check_dependency patch       2.5.4      ; then EXIT_STATUS=1; fi
    if ! check_dependency python3     3.4        ; then EXIT_STATUS=1; fi
    if ! check_dependency sed         4.1.5      ; then EXIT_STATUS=1; fi
    if ! check_dependency tar         1.22       ; then EXIT_STATUS=1; fi
    if ! check_dependency makeinfo    4.7        ; then EXIT_STATUS=1; fi  # texinfo
    if ! check_dependency xz          5.0.0      ; then EXIT_STATUS=1; fi
    if ! check_dependency kernel_vers 3.2        ; then EXIT_STATUS=1; fi  # linux
    if ! check_dependency perl_vers   5.8.8      ; then EXIT_STATUS=1; fi  # perl

    # check that yacc is a link to bison
    if [ ! -h /usr/bin/yacc -a "$(readlink -f /usr/bin/yacc)"="/usr/bin/bison.yacc" ]
    then
        echo "ERROR: /usr/bin/yacc needs to be a link to /usr/bin/bison.yacc"
        EXIT_STATUS=1
    fi

    # check that awk is a link to gawk
    if [ ! -h /usr/bin/awk -a "$(readlink -f /usr/bin/awk)"="/usr/bin/gawk" ]
    then
        echo "ERROR: /usr/bin/awk needs to be a link to /usr/bin/gawk"
        EXIT_STATUS=1
    fi

    # check G++ compilation
    echo 'int main(){}' > dummy.c && g++ -o dummy dummy.c
    if [ ! -x dummy ]
    then
        echo "ERROR: g++ compilation failed"
        EXIT_STATUS=1
    fi
    rm -f dummy.c dummy

    return $EXIT_STATUS
}

function install_static {
    FILENAME=$1
    FULLPATH="$LFS/$(basename $FILENAME | sed 's/__/\//g')"
    mkdir -p $(dirname $FULLPATH)
    cp $FILENAME $FULLPATH
}

function install_template {
    FILENAME=$1
    FULLPATH="$LFS/$(basename $FILENAME | sed 's/__/\//g')"
    mkdir -p $(dirname $FULLPATH)
    cp $FILENAME $FULLPATH
    shift
    for var in $@
    do
        sed -i "s/$var/${!var}/g" $FULLPATH
    done
}

function init_image {
    echo -n "Creating image file... "

    # create image file
    fallocate -l$LFS_IMG_SIZE $LFS_IMG

    # attach loop device
    LOOP=$(losetup -f)
    losetup $LOOP $LFS_IMG

    # partition the device
FDISK_STR="
g       # create GPT
n       # new partition
        # default 1st partition
        # default start sector (2048)
+512M   # 512 MiB
t       # modify parition type
uefi    # EFI type
n       # new partition
        # default 2nd partition
        # default start sector
        # default end sector
w       # write to device and quit
"
    FDISK_STR=$(echo "$FDISK_STR" | sed 's/ *#.*//g')
    # fdisk fails to get kernel to re-read the partition table
    # so ignore non-zero exit code, and manually re-read
    set +e
fdisk $LOOP &>> /dev/null <<EOF
$FDISK_STR
EOF
    set -e

    # reattach loop device to re-read partition table
    losetup -d $LOOP
    sleep 1 # give the kernel a sec
    losetup -P $LOOP $LFS_IMG
    LOOP_P1=${LOOP}p1
    LOOP_P2=${LOOP}p2

    # setup root partition
    mkfs -t $LFS_FS $LOOP_P2 &> /dev/null
    mkdir -p $LFS
    mount $LOOP_P2 $LFS

    # setup EFI partition
    mkfs.vfat $LOOP_P1 &> /dev/null
    mkdir -p $LFS/boot/efi
    mount -t vfat $LOOP_P1 $LFS/boot/efi

    # label the partitions
    dosfslabel $LOOP_P1 $LFSEFILABEL &> /dev/null
    e2label $LOOP_P2 $LFSROOTLABEL 

    echo "done."

    echo -n "Creating basic directory layout... "

    mkdir -p $LFS/{boot,dev,etc,home,lib64,media,mnt,opt,proc,run,srv,sys,tools,usr,var}
    mkdir -p $LFS/boot/grub
    mkdir -p $LFS/etc/{modprobe.d,opt,sysconfig}
    mkdir -p $LFS/media/{cdrom,floppy}
    mkdir -p $LFS/usr/{bin,lib/{,firmware},sbin}
    mkdir -p $LFS/usr/local/{bin,include,lib,sbin,share,src}
    mkdir -p $LFS/usr/local/share/{color,dict,doc,info,locale,man,misc,terminfo,zoneinfo}
    mkdir -p $LFS/usr/local/share/man/{1..8}
    mkdir -p $LFS/var/{cache,lib,local,log,mail,opt,spool}
    mkdir -p $LFS/var/lib/{color,misc,locate}

    install -d -m 0750 $LFS/root
    install -d -m 1777 $LFS/tmp $LFS/var/tmp

    # removed at end of build
    mkdir -p $LFS/home/tester
    chown 101:101 $LFS/home/tester
    mkdir -p $LFS/sources

    # create symlinks
    for i in bin lib sbin
    do
        ln -s usr/$i $LFS/$i
    done
    ln -s /run $LFS/var/run
    ln -s /run/lock $LFS/var/lock
    ln -s /proc/self/mounts $LFS/etc/mtab

    # install static files
    echo $LFSHOSTNAME > $LFS/etc/hostname
    for file in ./static/*
    do
        install_static $file
    done
    if [ -n "$KERNELCONFIG" ]
    then
        cp $KERNELCONFIG /boot/config-$KERNELVERS
    fi

    # install templates
    install_template ./templates/boot__grub__grub.cfg LFSROOTLABEL
    install_template ./templates/etc__fstab LFSROOTLABEL LFSEFILABEL LFSFSTYPE
    install_template ./templates/etc__hosts LFSHOSTNAME

    # make special device files
    mknod -m 600 $LFS/dev/console c 5 1
    mknod -m 666 $LFS/dev/null c 1 3

    # create login log files
    touch $LFS/var/log/{btmp,lastlog,faillog,wtmp}
    chgrp 13 $LFS/var/log/lastlog
    chmod 664  $LFS/var/log/lastlog
    chmod 600  $LFS/var/log/btmp

    # mount stuff from the host onto the target disk
    mount --bind /dev $LFS/dev
    mount --bind /dev/pts $LFS/dev/pts
    mount -t proc proc $LFS/proc
    mount -t sysfs sysfs $LFS/sys
    mount -t tmpfs tmpfs $LFS/run

    if [ -h $LFS/dev/shm ]; then
      mkdir -p $LFS/$(readlink $LFS/dev/shm)
    fi

    echo "done."
}

function get_packages {
    echo -n "Downloading packages to $LFS/sources... "
wget --quiet --no-clobber --directory-prefix $PACKAGE_DIR --input-file - <<EOF
$(cat $PACKAGE_LIST | cut -d"=" -f2)
EOF
    cp ./pkgs/* $LFS/sources
    echo "done."
}

function mount_image {
    # make sure everything is unmounted first
    unmount_image

    # attach loop device
    LOOP=$(losetup -f)
    LOOP_P1=${LOOP}p1
    LOOP_P2=${LOOP}p2
    losetup -P $LOOP $LFS_IMG
    sleep 1 # give the kernel a sec

    # mount root fs
    mount $LOOP_P2 $LFS

    # mount boot partition
    mount -t vfat $LOOP_P1 $LFS/boot/efi

    # mount stuff from the host onto the target disk
    mount --bind /dev $LFS/dev
    mount --bind /dev/pts $LFS/dev/pts
    mount -t proc proc $LFS/proc
    mount -t sysfs sysfs $LFS/sys
    mount -t tmpfs tmpfs $LFS/run
}

function unmount_image {
    # unmount everything
    local MOUNTED_LOCS=$(mount | grep $LFS)
    if [ -n "$MOUNTED_LOCS" ];
    then
        echo "$MOUNTED_LOCS" | cut -d" " -f3 | tac | xargs umount
    fi

    # detatch loop device
    local ATTACHED_LOOP=$(losetup | grep $LFS_IMG)
    if [ -n "$ATTACHED_LOOP" ]
    then
        losetup -d $(echo "$ATTACHED_LOOP" | cut -d" " -f1)
    fi
}

function build_package {
    local NAME=$1
    local NAME_OVERRIDE=$2

    echo -n "Building $NAME phase $PHASE... "

    local PKG_NAME=PKG_$([ -n "$NAME_OVERRIDE" ] && echo $NAME_OVERRIDE || echo $NAME | tr a-z A-Z)
    PKG_NAME=$(basename ${!PKG_NAME})

    local LOG_FILE=$LOG_DIR/${NAME}_phase${PHASE}.log

    local BUILD_INSTR="
        set -e
        pushd sources > /dev/null
        rm -rf $NAME
        mkdir $NAME
        tar -xf $PKG_NAME -C $NAME --strip-components=1
        cd $NAME
        $(cat ./phase${PHASE}/${NAME}.sh)
        popd
        rm -r sources/$NAME
    "

    pushd $LFS > /dev/null
    if $CHROOT
    then
        if ! chroot "$LFS" /usr/bin/env -i \
                HOME=/root \
                TERM=$TERM \
                PATH=/usr/bin:/usr/sbin &> $LOG_FILE \
                MAKEFLAGS=$MAKEFLAGS \
                ROOT_PASSWD=$ROOT_PASSWD \
                RUN_TESTS=$RUN_TESTS \
                KERNELVERS=$KERNELVERS \
                $(cat $PACKAGE_LIST) \
                /usr/bin/bash +h -c "$BUILD_INSTR" &> $LOG_FILE
        then
            echo -e "\nERROR: $NAME Phase $PHASE failed:"
            tail $LOG_FILE
            return 1
        fi
    elif ! (eval "$BUILD_INSTR") &> $LOG_FILE
    then
        echo -e "\nERROR: $NAME phase $PHASE failed:"
        tail $LOG_FILE
        return 1
    fi
    popd > /dev/null

    if $KEEP_LOGS
    then
        (cd $LOG_DIR && gzip $LOG_FILE)
    else
        rm $LOG_FILE
    fi

    echo "done."

    return 0
}

function build_phase {
    PHASE=$1

    if [ -n "$STARTPHASE" ]
    then
        if [ $PHASE -lt $STARTPHASE ] || { $FOUNDSTARTPHASE && $ONEOFF; }
        then
            echo "Skipping phase $PHASE"
            return 0
        else
            FOUNDSTARTPHASE=true
        fi
    fi

    if [ $PHASE -ne 1 -a ! -f $LFS/root/.phase$((PHASE-1)) ]
    then
        echo "ERROR: phases preceeding phase $PHASE have not been built"
        return 1
    fi

    echo -e "# #######\n# Phase $PHASE\n# ~~~~~~~"

    CHROOT=false
    if [ $PHASE -gt 2 ]
    then
        CHROOT=true
    fi

    while read pkg
    do
        if $FOUNDSTARTPKG && $ONEOFF
        then
            # already found one-off build, just quit
            return 0
        elif [ -z "$pkg" -o "${pkg:0:1}" == "#" ]
        then
            # skip comments
            continue
        elif [ -n "$STARTPKG" ] && ! $FOUNDSTARTPKG
        then
            # if start package is defined, skip until found
            if [ "$STARTPKG" == "$(echo $pkg | cut -d" " -f1)" ]
            then
                FOUNDSTARTPKG=true
                build_package $pkg
            else
                continue
            fi
        else
            build_package $pkg
        fi

    done < ./phase$PHASE/build_order.txt

    if [ -n "$STARTPKG" -a "$STARTPHASE" == "$PHASE" -a ! $FOUNDSTARTPKG ]
    then
        echo "ERROR: package build '$STARTPKG' not present in phase '$STARTPHASE'"
        return 1
    fi

    touch $LFS/root/.phase$PHASE

    return 0
}

function clean_image {
    unmount_image

    # delete img
    if [ -f $LFS_IMG ]
    then
        read -p "WARNING: This will delete ${LFS_IMG}. Continue? (Y/N): " CONFIRM
        if [[ $CONFIRM == [yY] || $CONFIRM == [yY][eE][sS] ]]
        then
            echo "Deleting ${LFS_IMG}..."
            rm $LFS_IMG
        fi
    fi

    # delete logs
    if [ -n "$(ls ./logs)" ]
    then
        rm -rf ./logs/*log ./logs/*gz
    fi
}


# ###############
# Parse arguments
# ~~~~~~~~~~~~~~~

cd $(dirname $0)
source ./config.sh

ONEOFF=false

while [ $# -gt 0 ]; do
  case $1 in
    -e|--check)
      check_dependencies
      exit
      ;;
    -o|--one-off)
      ONEOFF=true
      shift
      ;;
    -p|--start-phase)
      STARTPHASE="$2"
      shift
      shift
      ;;
    -a|--start-package)
      STARTPKG="$2"
      shift
      shift
      ;;
    -k|--kernel-config)
      KERNELCONFIG="$2"
      shift
      shift
      ;;
    -m|--mount)
      mount_image
      exit
      ;;
    -u|--umount)
      unmount_image
      exit
      ;;
    -c|--clean)
      clean_image
      exit
      ;;
    -v|--version)
      echo $LFS_VERSION
      exit
      ;;
    -h|--help)
      usage
      exit
      ;;
    *)
      echo "Unknown option $1"
      usage
      exit 1
      ;;
  esac
done

if [ -n "$STARTPHASE" ] &&
[ "$STARTPHASE" != 1 -a "$STARTPHASE" != 2 -a "$STARTPHASE" != 3 -a "$STARTPHASE" != 4 ]
then
    echo "ERROR: phase '$STARTPHASE' does not exist"
    exit 1
elif [ -n "$STARTPKG" -a -z "$STARTPHASE" ]
then
    echo "ERROR: -p|--start-phase must be defined if -a|--start-package is defined"
    exit 1
elif $ONEOFF && [ -z "$STARTPHASE" -a -z "$STARTPKG" ]
then
    echo "ERROR: -o|--one-off has no effect without a starting phase and/or package selected."
    exit 1
fi

FOUNDSTARTPKG=false
FOUNDSTARTPHASE=false


# #################
# Prepare for build
# ~~~~~~~~~~~~~~~~~

while read pkg;
do
    eval $pkg
    export $(echo $pkg | cut -d"=" -f1)
done < $PACKAGE_LIST

if [ -n "$STARTPHASE" ]
then
    if [ ! -f $LFS_IMG ]
    then
        echo "ERROR: $LFS_IMG is not present - cannot start from phase $STARTPHASE."
        exit 1
    fi
    mount_image
else
    if [ -f $LFS_IMG ]
    then
        echo "WARNING: $LFS_IMG is present. If you start from the beginning, this file will be deleted."
        read -p "Continue? (Y/N): " CONFIRM
        if [[ $CONFIRM == [yY] || $CONFIRM == [yY][eE][sS] ]]
        then
            echo -n "Cleaning... "
            yes | clean_image > /dev/null
            echo "done."
        else
            exit
        fi
    fi
    init_image
fi

get_packages

PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
LC_ALL=POSIX
export LC_ALL PATH CONFIG_SITE

trap "{ unmount_image; exit 1; }" ERR SIGINT

# ###########
# Start build
# ~~~~~~~~~~~

build_phase 1

$ONEOFF && $FOUNDSTARTPHASE && unmount_image && exit

build_phase 2

$ONEOFF && $FOUNDSTARTPHASE && unmount_image && exit

build_phase 3

# phase 3 cleanup
rm -rf $LFS/usr/share/{info,man,doc}/*
find $LFS/usr/{lib,libexec} -name \*.la -delete
rm -rf $LFS/tools

$ONEOFF && $FOUNDSTARTPHASE && unmount_image && exit

build_phase 4

# phase 4 cleanup
rm -rf $LFS/tmp/*
find $LFS/usr/lib $LFS/usr/libexec -name \*.la -delete
find $LFS/usr -depth -name $LFS_TGT\* | xargs rm -rf
rm -rf $LFS/home/tester
sed -i 's/^.*tester.*$//' $LFS/etc/{passwd,group}

# unmount and detatch image
unmount_image

