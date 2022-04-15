#!/usr/bin/env bash
set -e

LFS_VERSION=11.1

# #########
# Functions
# ~~~~~~~~~

function usage {
    echo -e "Welcome to MyLFS.\n" \
         "    When running the script without arguments, it will attempt to build the\n" \
         "entire project from beginning to end. Before starting any part of the build,\n" \
         "however, you should be sure to run the script with '--check' to verify the\n" \
         "dependencies on your system.\n" \
         "\n" \
         "    options: \n" \
         "        -v|--version        Print the LFS version this build is based on, then exit.\n" \
         "\n" \
         "        -V|--verbose        The script will output more information where applicable.\n" \
         "\n" \
         "        -f|--uefi           Build LFS with UEFI boot instead of the default BIOS boot.\n" \
         "\n" \
         "        -e|--check          Output LFS dependency version information, then exit.\n" \
         "                            It is recommended that you run this before proceeding\n" \
         "                            with the rest of the build.\n" \
         "\n" \
         "        -d|--download-pkgs  Download all packages into the 'pkgs' directory, then\n" \
         "                            exit.\n" \
         "\n" \
         "        -i|--init           Create the .img file, partition it, setup basic directory\n" \
         "                            structure, then exit.\n" \
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
         "        -h|--help           Show this message."
}

function check_dependency {
    local PROG=$1
    local MINVERS=$2
    local MAXVERS=$([ -n "$3" ] && echo $3 || echo "none")

    if ! command -v $PROG &> /dev/null
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
    local FILENAME=$1
    local FULLPATH="$LFS/$(basename $FILENAME | sed 's/__/\//g')"
    mkdir -p $(dirname $FULLPATH)
    cp $FILENAME $FULLPATH
}

function install_template {
    local FILENAME=$1
    local FULLPATH="$LFS/$(basename $FILENAME | sed 's/__/\//g')"
    mkdir -p $(dirname $FULLPATH)
    cp $FILENAME $FULLPATH
    shift
    for var in $@
    do
        sed -i "s/$var/${!var}/g" $FULLPATH
    done
}

function init_image {
    if [ $UID -ne 0 ]
    then
        echo "ERROR: must be run as root."
        exit 1
    fi

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

    # download packages into ./pkgs directory
    download_pkgs

    echo -n "Creating image file... "

    trap "echo 'init failed.' && exit 1" ERR

    if $VERBOSE
    then
        set -x
    fi

    # create image file
    fallocate -l$LFS_IMG_SIZE $LFS_IMG

    # hopefully banish any ghost images
    dd if=/dev/zero of=$LFS_IMG bs=1M count=1 conv=notrunc &> /dev/null

    # attach loop device
    export LOOP=$(losetup -f)
    losetup $LOOP $LFS_IMG

    # partition the device
    if $UEFI
    then
        FDISK_INSTR=$FDISK_INSTR_UEFI
    else
        FDISK_INSTR=$FDISK_INSTR_BIOS
    fi

    # remove spaces and comments
    FDISK_INSTR=$(echo "$FDISK_INSTR" | sed 's/ *#.*//')

    # fdisk fails to get kernel to re-read the partition table
    # so ignore non-zero exit code, and manually re-read
    trap - ERR
    set +e
    echo "$FDISK_INSTR" | fdisk $LOOP &> /dev/null
    set -e
    trap "echo 'init failed.' && unmount_image && exit 1" ERR

    # reattach loop device to re-read partition table
    losetup -d $LOOP
    sleep 1 # give the kernel a sec
    losetup -P $LOOP $LFS_IMG

    if $UEFI
    then
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
    else
        LOOP_P1=${LOOP}p1

        # setup root partition
        mkfs -t $LFS_FS $LOOP_P1 &> /dev/null
        mkdir -p $LFS
        mount $LOOP_P1 $LFS

        e2label $LOOP_P1 $LFSROOTLABEL
    fi
    rm -rf $LFS/lost+found

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
    cp ./pkgs/* $LFS/sources

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
    install_template ./templates/etc__hosts LFSHOSTNAME
    if $UEFI
    then
        install_template ./templates/etc__fstab LFSROOTLABEL LFSEFILABEL LFSFSTYPE
    else
        install_template ./templates/etc__fstab LFSROOTLABEL LFSFSTYPE
        sed -i "s/.*LFSEFILABEL.*//" $LFS/etc/fstab 
    fi

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

    set +x

    trap - ERR

    echo "done."
}

function cleanup_cancelled_download {
    local PKG=$PACKAGE_DIR/$(basename $1)
    [ -f $PKG ] && rm -f $PKG
}

function download_pkgs {
    { $VERBOSE && echo "Downloading packages... "; } || echo -n "Downloading packages... "

    local PACKAGE_URLS=$(cat $PACKAGE_LIST | cut -d"=" -f2)
    local ALREADY_DOWNLOADED=$(ls $PACKAGE_DIR)

    for url in $PACKAGE_URLS
    do
        trap "{ cleanup_cancelled_download $url; exit }" ERR SIGINT

        $VERBOSE && echo -n "Downloading '$url'... "
        if ! echo $ALREADY_DOWNLOADED | grep $(basename $url) > /dev/null
        then
            if ! wget --quiet --directory-prefix $PACKAGE_DIR $url
            then
                echo -e "\nERROR: Failed to download URL '$url'"
                exit 1
            fi
            $VERBOSE && echo "done."
        else
            $VERBOSE && echo "already have it - skipping."
        fi

        trap - ERR SIGINT
    done

    echo "done."
}

function mount_image {
    if [ $UID -ne 0 ]
    then
        echo "ERROR: must be run as root."
        exit 1
    fi

    if [ ! -f $LFS_IMG ]
    then
        echo "ERROR: $LFS_IMG not found - cannot mount."
        exit 1
    fi

    # make sure everything is unmounted first
    unmount_image

    # attach loop device
    export LOOP=$(losetup -f)
    LOOP_P1=${LOOP}p1
    LOOP_P2=${LOOP}p2
 
    if $UEFI
    then
        losetup -P $LOOP $LFS_IMG
        sleep 1 # give the kernel a sec

        # mount root fs
        mount $LOOP_P2 $LFS

        # mount boot partition
        mount -t vfat $LOOP_P1 $LFS/boot/efi
    else
        losetup -P $LOOP $LFS_IMG
        sleep 1

        mount $LOOP_P1 $LFS
    fi

    # mount stuff from the host onto the target disk
    mount --bind /dev $LFS/dev
    mount --bind /dev/pts $LFS/dev/pts
    mount -t proc proc $LFS/proc
    mount -t sysfs sysfs $LFS/sys
    mount -t tmpfs tmpfs $LFS/run
}

function unmount_image {
    if [ $UID -ne 0 ]
    then
        echo "ERROR: must be run as root."
        exit 1
    fi

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
        if ! chroot "$LFS" /usr/bin/env \
                HOME=/root \
                TERM=$TERM \
                PATH=/usr/bin:/usr/sbin \
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
    if [ $UID -ne 0 ]
    then
        echo "ERROR: must be run as root."
        exit 1
    fi

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

    if [ $PHASE -eq 5 ]
    then
        PHASE=5_$({ $UEFI && echo "uefi"; } || echo "bios")
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
    if [ $UID -ne 0 ]
    then
        echo "ERROR: must be run as root."
        exit 1
    fi

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
        rm -rf ./logs/*
    fi
}


# ###############
# Parse arguments
# ~~~~~~~~~~~~~~~

cd $(dirname $0)
source ./config.sh
while read pkg;
do
    eval $pkg
    export $(echo $pkg | cut -d"=" -f1)
done < $PACKAGE_LIST


VERBOSE=false
CHECKDEPS=false
DOWNLOAD=false
INIT=false
ONEOFF=false
FOUNDSTARTPKG=false
FOUNDSTARTPHASE=false
MOUNT=false
UNMOUNT=false
CLEAN=false
export UEFI=false # exported for linux.sh

while [ $# -gt 0 ]; do
  case $1 in
    -v|--version)
      echo $LFS_VERSION
      exit
      ;;
    -V|--verbose)
      VERBOSE=true
      shift
      ;;
    -f|--uefi)
      UEFI=true
      shift
      ;;
    -e|--check)
      CHECKDEPS=true
      shift
      ;;
    -d|--download-pkgs)
      DOWNLOAD=true
      shift
      ;;
    -i|--init)
      INIT=true
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
    -o|--one-off)
      ONEOFF=true
      shift
      ;;
    -k|--kernel-config)
      KERNELCONFIG="$2"
      shift
      shift
      ;;
    -m|--mount)
      MOUNT=true
      shift
      ;;
    -u|--umount)
      UNMOUNT=true
      shift
      ;;
    -c|--clean)
      CLEAN=true
      shift
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

OPCOUNT=0
for OP in CHECKDEPS DOWNLOAD INIT STARTPHASE MOUNT UNMOUNT CLEAN
do
    OP="${!OP}"
    if [ -n "$OP" -a "$OP" != "false" ]
    then
        OPCOUNT=$((OPCOUNT+1))
    fi

    if [ $OPCOUNT -gt 1 ]
    then
        echo "ERROR: too many options."
        exit 1
    fi
done

if [ -n "$STARTPHASE" ] &&
[ "$STARTPHASE" != 1 -a "$STARTPHASE" != 2 -a "$STARTPHASE" != 3 -a "$STARTPHASE" != 4 -a "$STARTPHASE" != 5 ]
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


# ###########
# Start build
# ~~~~~~~~~~~

trap "echo 'build failed.' && cd $FULLPATH && unmount_image && exit 1" ERR
trap "echo 'build cancelled.' && cd $FULLPATH && unmount_image && exit" SIGINT

# Perform single operations
$CHECKDEPS && check_dependencies && exit
$DOWNLOAD && download_pkgs && exit
$INIT && init_image && exit
$MOUNT && mount_image && exit
$UNMOUNT && unmount_image && exit
$CLEAN && clean_image && exit

if [ -n "$STARTPHASE" ]
then
    if [ ! -f $LFS_IMG ]
    then
        echo "ERROR: $LFS_IMG not found - cannot start from phase $STARTPHASE."
        exit 1
    fi
    mount_image
else
    init_image
fi

PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
LC_ALL=POSIX
export LC_ALL PATH CONFIG_SITE

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

$ONEOFF && $FOUNDSTARTPHASE && unmount_image && exit

build_phase 5

# final cleanup
rm -rf $LFS/tmp/*
find $LFS/usr/lib $LFS/usr/libexec -name \*.la -delete
find $LFS/usr -depth -name $LFS_TGT\* | xargs rm -rf
rm -rf $LFS/home/tester
sed -i 's/^.*tester.*$//' $LFS/etc/{passwd,group}

# unmount and detatch image
unmount_image

