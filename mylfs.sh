#!/usr/bin/env bash
set -e


# #########
# Functions
# ~~~~~~~~~

repeat_echo(){
	local start=1
	local end=${1:-80}
	local str="${2:-=}"
	local range=$(seq $start $end)
	for i in $range ; do echo -n "${str}"; done
}

function usage {
cat <<EOF
Welcome to MyLFS.

    WARNING: Most of the functionality in this script requires root privilages,
and involves the partitioning, mounting and unmounting of device files. Use at
your own risk.

    If you would like to build Linux From Scratch from beginning to end, just
run the script with the '--build-all' command. Otherwise, you can build LFS one step
at a time by using the various commands outlined below. Before building anything
however, you should be sure to run the script with '--check' to verify the
dependencies on your system. If you want to install the IMG file that this
script produces onto a storage device, you can specify '--install /dev/<devname>'
on the commandline. Be careful with that last one - it WILL destroy all partitions
on the device you specify.

    options:
        -v|--version        Print the LFS version this build is based on, then exit.

        -V|--verbose        The script will output more information where applicable
                            (careful what you wish for).

        -e|--check          Output LFS dependency version information, then exit.
                            It is recommended that you run this before proceeding
                            with the rest of the build.

        -b|--build-all      Run the entire script from beginning to end.

        -x|--extend         Pass in the path to a custom build extension. See the
                            'example_extension' directory for reference.

        -d|--download-pkgs  Download all packages into the 'pkgs' directory, then
                            exit.

        -i|--init           Create the .img file, partition it, setup basic directory
                            structure, then exit.

        -p|--start-phase
        -a|--start-package  Select a phase and optionally a package
                            within that phase to start building from.
                            These options are only available if the preceeding
                            phases have been completed. They should really only
                            be used when something broke during a build, and you
                            don't want to start from the beginning again.

        -o|--one-off        Only build the specified phase/package.

        -k|--kernel-config  Optional path to kernel config file to use during linux
                            build.

        -m|--mount
        -u|--umount         These options will mount or unmount the disk image to the
                            filesystem, and then exit the script immediately.
                            You should be sure to unmount prior to running any part of
                            the build, since the image will be automatically mounted
                            and then unmounted at the end.

        -n|--install        Specify the path to a block device on which to install the
                            fully built img file.

        -c|--clean          This will unmount and delete the image, and clear the
                            logs.

        -h|--help           Show this message."
EOF
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
    local EXIT_STATUS=0

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
    cp -f $FILENAME $FULLPATH
}

function install_template {
    local FILENAME=$1
    local FULLPATH="$LFS/$(basename $FILENAME | sed 's/__/\//g')"
    mkdir -p $(dirname $FULLPATH)
    cat $FILENAME | envsubst > $FULLPATH
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

    echo -n "Creating image file... "

    trap "echo 'init failed.' && exit 1" ERR

    $VERBOSE && set -x

    # create image file
    fallocate -l$LFS_IMG_SIZE $LFS_IMG

    # attach loop device
    export LOOP=$(losetup -f) # export for grub.sh
    local LOOP_P1=${LOOP}p1
    losetup $LOOP $LFS_IMG

    # partition the device.
    # remove spaces and comments from instructions
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

    sleep 1 # give the kernel another sec

    LFSPARTUUID=$(lsblk -o PARTUUID $LOOP | tail -1) # needed for grub.cfg

    # setup root partition
    mkfs -t $LFS_FS $LOOP_P1 &> /dev/null
    mkdir -p $LFS
    mount -t $LFS_FS $LOOP_P1 $LFS

    e2label $LOOP_P1 $LFSROOTLABEL

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
    for f in ./static/*
    do
        install_static $f
    done
    if [ -n "$KERNELCONFIG" ]
    then
        cp $KERNELCONFIG /boot/config-$KERNELVERS
    fi

    # install templates
    for f in ./templates/*
    do
        install_template $f
    done

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
    if [ -n "$1" ]
    then
        # if an extension is being built, it will
        # override the pkgs and pkgs.sh paths
        local PACKAGE_DIR=$1/pkgs
        local PACKAGE_LIST=$1/pkgs.sh
    fi

    mkdir -p $PACKAGE_DIR

    [ -f "$PACKAGE_LIST" ] || { echo "ERROR: $PACKAGE_LIST is missing." && exit 1; }

    local PACKAGE_URLS=$(cat $PACKAGE_LIST | grep "^[^#]" | cut -d"=" -f2)
    local ALREADY_DOWNLOADED=$(ls $PACKAGE_DIR)

    { $VERBOSE && echo "Downloading packages... "; } || echo -n "Downloading packages... "

    for url in $PACKAGE_URLS
    do
        trap "cleanup_cancelled_download $url && exit" ERR SIGINT

        $VERBOSE && echo -n "Downloading '$url'... "
        if ! echo $ALREADY_DOWNLOADED | grep $(basename $url) > /dev/null
        then
            if ! curl --location --silent --output $PACKAGE_DIR/$(basename $url) $url
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

    $VERBOSE && set -x

    # make sure everything is unmounted first
    unmount_image

    # attach loop device
    export LOOP=$(losetup -f) # export for grub.sh
    local LOOP_P1=${LOOP}p1

    losetup -P $LOOP $LFS_IMG

    sleep 1
    mount $LOOP_P1 $LFS

    # mount stuff from the host onto the target disk
    mount --bind /dev $LFS/dev
    mount --bind /dev/pts $LFS/dev/pts
    mount -t proc proc $LFS/proc
    mount -t sysfs sysfs $LFS/sys
    mount -t tmpfs tmpfs $LFS/run

    set +x
}

function unmount_image {
    if [ $UID -ne 0 ]
    then
        echo "ERROR: must be run as root."
        exit 1
    fi

    $VERBOSE && set -x

    # unmount everything
    local GREP_FOR=$({ [ -n "$INSTALL_TGT" ] && echo "$LFS\|$INSTALL_MOUNT"; } || echo "$LFS")
    local MOUNTED_LOCS=$(mount | grep $GREP_FOR)
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

    set +x
}

function build_package {
    local NAME=$1
    local NAME_OVERRIDE=$2

    { $VERBOSE && echo "Building $NAME phase $PHASE section $PHASESECTION..."; } || echo -n "Building $NAME phase $PHASE section $PHASESECTION... "

    local PKG_NAME=PKG_$([ -n "$NAME_OVERRIDE" ] && echo $NAME_OVERRIDE || echo $NAME | tr a-z A-Z)
    PKG_NAME=$(basename ${!PKG_NAME})

    local LOG_FILE=$([ $PHASE -eq 5 ] && echo "$EXTENSION/logs/${NAME}.log" || echo "$LOG_DIR/${PHASESECTION}/${NAME}_phase${PHASE}.log")
    local SCRIPT_PATH=$([ $PHASE -eq 5 ] && echo $EXTENSION/${NAME}.sh || echo ./$PHASESECTION/phase${PHASE}/${NAME}.sh)

    if ! [ -d $LOG_DIR/$PHASESECTION ]; then mkdir -p $LOG_DIR/$PHASESECTION; fi

    local BUILD_INSTR="
        set -ex
        pushd sources > /dev/null
        rm -rf $NAME
        mkdir $NAME
        tar -xf $PKG_NAME -C $NAME --strip-components=1
        cd $NAME
        $(cat $SCRIPT_PATH)
        popd
        rm -r sources/$NAME
    "

    pushd $LFS > /dev/null

    if $CHROOT
    then
        chroot "$LFS" /usr/bin/env \
                        HOME=/root \
                        TERM=$TERM \
                        PATH=/usr/bin:/usr/sbin \
                        /usr/bin/bash +h -c "$BUILD_INSTR" |& { $VERBOSE && tee $LOG_FILE || cat > $LOG_FILE; }
    else
        eval "$BUILD_INSTR" |& { $VERBOSE && tee $LOG_FILE || cat > $LOG_FILE; }
    fi

    if [ $PIPESTATUS -ne 0 ]
    then
        set +x
        echo -e "\nERROR: $NAME phase $PHASE failed:"
        tail $LOG_FILE
        return 1
    fi

    popd > /dev/null

    if $KEEP_LOGS
    then
        (cd $LOG_DIR && gzip -f $LOG_FILE)
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
    PHASESECTION=lfs
    if ! [ -e $2 ]; then PHASESECTION=$2; fi

    if [ -n "$STARTPHASE" ]
    then
        if [ $PHASE -lt $STARTPHASE ] || { $FOUNDSTARTPHASE && $ONEOFF; }
        then
            echo "Skipping phase $PHASE in $PHASESECTION section"
            return 0
        else
            FOUNDSTARTPHASE=true
        fi
    fi

    if [ $PHASE -ne 1 -a ! -f $LFS/root/.$PHASESECTION/.phase$((PHASE-1)) ]
    then
        echo "ERROR: phases preceeding phase $PHASE have not been built"
        return 1
    fi
    SSTR="Section $PHASESECTION. Phase $PHASE"
    HOUT="# "
    HOUT+=$(repeat_echo ${#SSTR} '#';echo)
    HOUT+="\n# ${SSTR}\n"
    HOUT+="# $(repeat_echo ${#SSTR} '~';echo)"
    echo -e $HOUT

    source ./$PHASESECTION/config.sh

    local PHASE_DIR=./$PHASESECTION/phase$PHASE 

    # Phase 5 == a build extension
#    [ $PHASE -eq 5 ] && PHASE_DIR=$EXTENSION

    # make sure ./logs/ and ./logs/$PHASESECTION dir exists
    mkdir -p $LOG_DIR/$PHASESECTION

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
                build_package $pkg || return 1
            else
                continue
            fi
        else
            build_package $pkg || return 1
        fi

    done < $PHASE_DIR/build_order.txt

    if [ -n "$STARTPKG" -a "$STARTPHASE" == "$PHASE" -a ! $FOUNDSTARTPKG ]
    then
        echo "ERROR: package build '$STARTPKG' not present in phase '$STARTPHASE'"
        return 1
    fi
    if ! [ -d $LFS/root/.$PHASESECTION ]; then mkdir -p $LFS/root/.$PHASESECTION; fi
    touch $LFS/root/.$PHASESECTION/.phase$PHASE

    return 0
}

function build_extension {
    if [ $UID -ne 0 ]
    then
        echo "ERROR: must be run as root."
        return 1
    elif [ ! -d "$EXTENSION" ]
    then
        echo "ERROR: extension '$EXTENSION' is not a directory, or does not exist."
        return 1
    elif [ ! -f "$EXTENSION/pkgs.sh" ]
    then
        echo "ERROR: extension '$EXTENSION' is missing a 'pkgs.sh' file."
        return 1
    elif [ ! -f "$EXTENSION/build_order.txt" ]
    then
        echo "ERROR: extension '$EXTENSION' is missing a 'build_order.txt' file."
        return 1
    fi

    mkdir -p $EXTENSION/{logs,pkgs}

    # read in extension config.sh if present
    [ -f "$EXTENSION/config.sh" ] && source "$EXTENSION/config.sh"

    # read pkgs.sh
    source "$EXTENSION/pkgs.sh"

    # download extension packages
    download_pkgs $EXTENSION

    $VERBOSE && set -x

    # copy packages onto LFS image
    cp -f $EXTENSION/pkgs/* $LFS/sources/

    # install static files if present
    if [ -d "$EXTENSION/static" ]
    then
        for f in $EXTENSION/static/*
        do
            install_static $f
        done
    fi

    # install template files if present
    if [ -d "$EXTENSION/templates" ]
    then
        for f in $EXTENSION/templates/*
        do
            install_template $f
        done
    fi

    # build extension
    build_phase 5 || return 1
}

function install_image {
    if [ $UID -ne 0 ]
    then
        echo "ERROR: must be run as root."
        exit 1
    fi

    if [ ! -f $LFS_IMG ]
    then
        echo "ERROR: $LFS_IMG does not exist. Be sure to build LFS completely before attempting to install."
        exit 1
    fi

    local PART_PREFIX=""
    case "$(basename $INSTALL_TGT)" in
      sd[a-z])
        PART_PREFIX=""
        ;;
      nvme[0-9]n[1-9])
        PART_PREFIX="p"
        ;;
      *)
        echo "ERROR: Unsupported device name '$INSTALL_TGT'."
        exit 1
        ;;
    esac

    read -p "WARNING: This will delete all contents of the device '$INSTALL_TGT'. Continue? (Y/N): " CONFIRM
    if [[ $CONFIRM != [yY] && $CONFIRM != [yY][eE][sS] ]]
    then
        echo "Cancelled."
        exit
    fi

    echo "Installing LFS onto ${INSTALL_TGT}... "

    $VERBOSE && set -x
 
    # partition the device.
    # remove spaces and comments
    FDISK_INSTR=$(echo "$FDISK_INSTR" | sed 's/ *#.*//')

    if ! echo "$FDISK_INSTR" | fdisk $INSTALL_TGT |& { $VERBOSE && cat || cat > /dev/null; }
    then
        echo "ERROR: failed to format $INSTALL_TGT. Consider manually clearing $INSTALL_TGT's parition table."
        exit
    fi
    partprobe $INSTALL_TGT

    trap "echo 'install failed.' && unmount_image && exit 1" ERR

    mkdir -p $LFS $INSTALL_MOUNT

    # mount IMG file
    local LOOP=$(losetup -f)
    local LOOP_P1=${LOOP}p1
    losetup -P $LOOP $LFS_IMG

    # setup install partition
    local INSTALL_P1="${INSTALL_TGT}${PART_PREFIX}1"
    mkfs -t $LFS_FS $INSTALL_P1 &> /dev/null
    e2label $INSTALL_P1 $LFSROOTLABEL

    # mount install partition
    mount $INSTALL_P1 $INSTALL_MOUNT
    mount $LOOP_P1 $LFS

    $VERBOSE && echo "Copying files... " || echo -n "Copying files... "
    cp -r $LFS/* $INSTALL_MOUNT/
    echo "done."

    # make sure grub.cfg is pointing at the right drive
    local PARTUUID=$(lsblk -o PARTUUID $INSTALL_TGT | tail -1)
    sed -Ei "s/root=PARTUUID=[0-9a-z-]+/root=PARTUUID=${PARTUUID}/" $INSTALL_MOUNT/boot/grub/grub.cfg

    mount --bind /dev $INSTALL_MOUNT/dev
    mount --bind /dev/pts $INSTALL_MOUNT/dev/pts
    mount -t sysfs sysfs $INSTALL_MOUNT/sys

    local GRUB_CMD="grub-install $INSTALL_TGT --target i386-pc"

    $VERBOSE && echo "Installing GRUB. This may take a few minutes... " || echo -n "Installing GRUB. This may take a few minutes... "
    chroot $INSTALL_MOUNT /usr/bin/bash -c "$GRUB_CMD" |& { $VERBOSE && cat || cat > /dev/null; }
    echo "done."

    set +x

    trap - ERR
    unmount_image

    echo "Installed successfully."
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

function mainLFSbuild {
    # ###########
    # Start build
    # ~~~~~~~~~~~

    # Perform single operations
    $CHECKDEPS && check_dependencies && exit
    $DOWNLOAD && download_pkgs && exit
    $INIT && download_pkgs && init_image && unmount_image && exit
    $MOUNT && mount_image && exit
    $UNMOUNT && unmount_image && exit
    $CLEAN && clean_image && exit
    [ -n "$INSTALL_TGT" ] && install_image && exit

    if [ -n "$STARTPHASE" ]
    then
        download_pkgs
        mount_image
    elif $BUILDALL
    then
        download_pkgs
        init_image
    else
        usage
        exit
    fi
    SECTION= $2 || lfs
    PATH=$LFS/tools/bin:$PATH
    CONFIG_SITE=$LFS/usr/share/config.site
    LC_ALL=POSIX
    export LC_ALL PATH CONFIG_SITE

    trap "echo 'build cancelled.' && cd $FULLPATH && unmount_image && exit" SIGINT
    trap "echo 'build failed.' && cd $FULLPATH && unmount_image && exit 1" ERR

    build_phase 1 $SECTION

    $ONEOFF && $FOUNDSTARTPHASE && unmount_image && exit

    build_phase 2 $SECTION

    $ONEOFF && $FOUNDSTARTPHASE && unmount_image && exit

    build_phase 3 $SECTION

    # phase 3 cleanup
    rm -rf $LFS/usr/share/{info,man,doc}/*
    find $LFS/usr/{lib,libexec} -name \*.la -delete
    rm -rf $LFS/tools

    $ONEOFF && $FOUNDSTARTPHASE && unmount_image && exit

    build_phase 4 $SECTION

    $ONEOFF && $FOUNDSTARTPHASE && unmount_image && exit

    [ -n "$EXTENSION" ] && build_extension

    # final cleanup
    rm -rf $LFS/tmp/*
    find $LFS/usr/lib $LFS/usr/libexec -name \*.la -delete
    find $LFS/usr -depth -name $LFS_TGT\* | xargs rm -rf
    rm -rf $LFS/home/tester
    sed -i 's/^.*tester.*$//' $LFS/etc/{passwd,group}

    # unmount and detatch image
    unmount_image

    echo "build successful."

}

function startISO {
:
}



# ###############
# Parse arguments
# ~~~~~~~~~~~~~~~

cd $(dirname $0)

# import config vars
source ./config.sh

# import package list
source ./pkgs.sh


VERBOSE=false
CHECKDEPS=false
BUILDALL=false
BUILDISO=false
DOWNLOAD=false
INIT=false
ONEOFF=false
FOUNDSTARTPKG=false
FOUNDSTARTPHASE=false
MOUNT=false
UNMOUNT=false
CLEAN=false
STARTSECTION=lfs

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
    -e|--check)
      CHECKDEPS=true
      shift
      ;;
    -b|--build-all)
      BUILDALL=true
      shift
      ;;
    -s|--build-iso)
      BUILDISO=true
      shift
      ;;
    -x|--extend)
      EXTENSION="$2"
      shift
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
    -t|--phase-id)
      STARTSECTION="$2"
      [ -z "$STARTSECTION" ] && echo "ERROR: $1 missing argument." && exit 1
      shift
      shift
      ;;
    -p|--start-phase)
      STARTPHASE="$2"
      [ -z "$STARTPHASE" ] && echo "ERROR: $1 missing argument." && exit 1
      shift
      shift
      ;;
    -a|--start-package)
      STARTPKG="$2"
      [ -z "$STARTPKG" ] && echo "ERROR: $1 missing argument." && exit 1
      shift
      shift
      ;;
    -o|--one-off)
      ONEOFF=true
      shift
      ;;
    -k|--kernel-config)
      KERNELCONFIG="$2"
      [ -z "$KERNELCONFIG" ] && echo "ERROR: $1 missing argument." && exit 1
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
    -n|--install)
      INSTALL_TGT="$2"
      [ -z "$INSTALL_TGT" ] && echo "ERROR: $1 missing argument." && exit 1
      shift
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
for OP in BUILDISO BUILDALL CHECKDEPS DOWNLOAD INIT STARTPHASE MOUNT UNMOUNT INSTALL_TGT CLEAN
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

if [ -n "$STARTPHASE" ]
then
    if ! [[ "$STARTPHASE" =~ ^[1-5]$ ]]
    then
        echo "ERROR: -p|--start-phase must specify a number between 1 and 5."
        exit 1
    elif [ "$STARTPHASE" -eq 5 ] && [ -z "$EXTENSION" ]
    then
        echo "ERROR: phase 5 only exists if an -x|--extend has been specified."
        exit 1
    elif [ ! -f $LFS_IMG ]
    then
        echo "ERROR: $LFS_IMG not found - cannot start from phase $STARTPHASE."
        exit 1
    fi
fi

if [ -n "$STARTPKG" -a -z "$STARTPHASE" ]
then
    echo "ERROR: -p|--start-phase must be defined if -a|--start-package is defined."
    exit 1
elif $ONEOFF && [ -z "$STARTPHASE" ]
then
    echo "ERROR: -o|--one-off has no effect without a starting phase selected."
    exit 1
fi

if [ -n "$EXTENSION" ]
then
    if ! $BUILDALL && [ -z "$STARTPHASE" ]
    then
        echo "ERROR: -x|--extend has no effect without either -b|--build-all or -p|--start-phase set."
        exit 1
    elif $ONEOFF && [ "$STARTPHASE" -ne 5 ]
    then
        echo "ERROR: -x|--extend has no effect if -o|--one-off is set and -p|--start-phase != 5."
        exit 1
    elif [ ! -d "$EXTENSION" ]
    then
        echo "ERROR: '$EXTENSION' is not a directory or does not exist."
    fi

    # get full path to extension
    EXTENSION="$(cd $(dirname $EXTENSION) && pwd)/$(basename $EXTENSION)"
fi

if $BUILDISO
then
    startISO
else
    mainLFSbuild $STARTSECTION
fi

