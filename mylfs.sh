#!/usr/bin/env bash
set -ueEo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# include helper scripts
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/packages.sh"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/version-check.sh"

usage() {
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
on the commandline. Be careful with that last one -- it WILL destroy all partitions
on the device you specify.

    options:
        -V|--version            Print the LFS version this build is based on, then exit.

        -v                      Show more output.
        -vv                     Show even more output (this is probably what you want).
        -vvv                    Show all build output.

        -D|--systemd            Build the Systemd version of LFS.

        -e|--check              Output LFS dependency version information, then exit.
                                It is recommended that you run this before proceeding
                                with the rest of the build.

        -b|--build-all          Run the entire script from beginning to end.

        -x|--extend             Pass in the path to a custom build extension. See the
                                'example_extension' directory for reference.

        -d|--download-packages  Download all packages into the 'packages' directory, then
                                exit.
        -s|--skip-download      Skip the download package step in operations that normally
                                include this step by default.

        -i|--init               Create the .img file, partition it, setup basic directory
                                structure, then exit.
        -t|--skip-init          Skip the init step in operations that normally include this
                                step by default.

        -p|--start-phase
        -a|--start-package      Select a phase and optionally a package
                                within that phase to start building from.
                                These options are only available if the preceeding
                                phases have been completed. They should really only
                                be used when something broke during a build, and you
                                don't want to start from the beginning again.

        -o|--one-off            Used in combination with the above two arguments; only
                                build the phase/package specified by -p|--start-phase
                                and -a|--start-package.

        -y|--end-phase
        -z|--end-package        Phase and optionally a package *before* which to halt
                                the build. This is useful for a number of use cases
                                including if you want to experiment with a manual build
                                on a specific package (e.g. the Linux kernel) but would
                                like to automate the previous package builds.

        -r|--drop-shell         Starts an interactive bash session inside of each extracted
                                package directory rather than executing any build scripts.
                                This can be useful for issuing and validating build commands
                                manually. You will most likely want to use this together
                                with -p|--start-phase, -a|--start-package and -o|--one-off,
                                unless you intend to build more than one or even all packages
                                manually.

        -k|--kernel-config      Optional path to kernel config file to use during linux
                                build.

        -m|--mount
        -u|--umount             These options will mount or unmount the disk image to the
                                filesystem, and then exit the script immediately.
                                You should be sure to unmount prior to running any part of
                                the build, since the image will be automatically mounted
                                and then unmounted at the end.

        -n|--install            Specify the path to a block device on which to install the
                                fully built img file.

        -c|--clean              This will unmount and delete the image, and clear the
                                logs.

        -h|--help               Show this message.
EOF
}

check_root_user() {
    if (( UID != 0 ))
    then
        log_error "must be run as root"
        return 1
    fi
}

install_static() {
    local filename=${1:?install_static(): filename required}
    local fullpath
    fullpath="$LFS/$(basename "$filename" | sed 's/__/\//g')"
    mkdir -p "$(dirname "$fullpath")"
    cp -f "$filename" "$fullpath"
}

install_template() {
    local filename=${1:?install_template(): filename required}
    local fullpath
    fullpath="$LFS/$(basename "$filename" | sed 's/__/\//g')"
    mkdir -p "$(dirname "$fullpath")"
    envsubst > "$fullpath" < "$filename"
}

init_image() {

    if (( SKIPINIT )); then
        log_warning "skipping image init"
        return 0
    fi

    if ! check_root_user; then
        return 1
    fi

    if [[ -f $LFS_IMG ]]; then
        if prompt_warning "$LFS_IMG is present; proceeding will delete this file"; then
            autoclean() { echo y | clean_image >/dev/null; }
            with_log "cleaning $LFS_IMG" autoclean
        else
            return 1
        fi
    fi

    # create image file
    with_log "allocating $LFS_IMG" fallocate -l"$LFS_IMG_SIZE" "$LFS_IMG"

    # attach loop device
    export LOOP  # export for grub.sh
    LOOP=$(losetup -f)
    local LOOP_P1=${LOOP}p1
    with_log "attaching $LFS_IMG to $LOOP" losetup "$LOOP" "$LFS_IMG"

    format_img() { 
        # remove spaces and comments from instructions
        local fdisk_instr
        # shellcheck disable=SC2001
        fdisk_instr=$(echo "$FDISK_INSTR" | sed 's/ *#.*//')
        # fdisk fails to get kernel to re-read the partition table
        # so ignore non-zero exit code, and manually re-read
        set +e
        echo "$fdisk_instr" | fdisk "$LOOP" &> /dev/null;
        set -e
        return 0;
    }
    with_log "partitioning $LOOP" format_img

    reattach() { losetup -d "$LOOP"; sleep 2; losetup -P "$LOOP" "$LFS_IMG"; }
    with_log "reattaching $LOOP" reattach

    # exporting for grub.cfg
    export LFS_PARTUUID
    label_partition() {
        LFS_PARTUUID="$(lsblk -o PARTUUID "$LOOP_P1" | tail -1)"
        while [[ -z $LFS_PARTUUID ]]; do
            # sometimes it takes a few seconds for the PARTUUID to be readable
            sleep 1
            LFS_PARTUUID="$(lsblk -o PARTUUID "$LOOP_P1" | tail -1)"
        done
    }
    with_log "exporting ${LOOP_P1}'s PARTUUID label" label_partition

    # setup root partition
    mkfs -t "$LFS_FS_TYPE" "$LOOP_P1" &> /dev/null
    mkdir -p "$LFS"
    mount -t "$LFS_FS_TYPE" "$LOOP_P1" "$LFS"

    e2label "$LOOP_P1" "$LFS_ROOT_LABEL"

    # LFS 12.4 Section 4.2
    mkdir -p "$LFS/"{etc,var}
    mkdir -p "$LFS/usr/"{bin,lib,sbin}
    local i
    for i in bin lib sbin; do
        ln -s "usr/$i" "$LFS/$i"
    done
    case $(uname -m) in
        x86_64) mkdir -p "$LFS/lib64" ;;
    esac
    mkdir -p "$LFS/tools"

    # LFS 12.4 Section 7.5
    mkdir -p "$LFS/etc/"{opt,sysconfig}
    mkdir -p "$LFS/lib/firmware"
    mkdir -p "$LFS/media/"{floppy,cdrom}
    mkdir -p "$LFS/usr/"{,local/}{include,src}
    mkdir -p "$LFS/usr/lib/locale"
    mkdir -p "$LFS/usr/local/"{bin,lib,sbin}
    mkdir -p "$LFS/usr/"{,local/}share/{color,dict,doc,info,locale,man}
    mkdir -p "$LFS/usr/"{,local/}share/{misc,terminfo,zoneinfo}
    mkdir -p "$LFS/usr/"{,local/}share/man/man{1..8}
    mkdir -p "$LFS/var/"{cache,local,log,mail,opt,spool}
    mkdir -p "$LFS/var/lib/"{color,misc,locate}
    ln -sf /run "$LFS/var/run"
    ln -sf /run/lock "$LFS/var/lock"
    install -d -m 0750 "$LFS/root"
    install -d -m 1777 "$LFS/tmp" "$LFS/var/tmp"

    # LFS 12.4 Section 7.6
    ln -s /proc/self/mounts "$LFS/etc/mtab"

    if (( BUILDSYSTEMD )); then
        echo "$ETC_PASSWD_SYSTEMD" > "$LFS/etc/passwd"
        echo "$ETC_GROUP_SYSTEMD" > "$LFS/etc/group"
        mkdir -p "$LFS/etc/systemd/network"
        echo "$ETC_SYSTEMD_NETWORK" > "$LFS/etc/systemd/network/10-eth-static.network"
        echo "$ETC_FSTAB_SYSTEMD" > "$LFS/etc/fstab"
        echo "$ETC_SYSTEMD_VCONSOLE" > "$LFS/etc/vconsole"
        echo "$ETC_LOCALECONF_SYSTEMD" > "$LFS/etc/locale.conf"
    else
        echo "$ETC_PASSWD_SYSVINIT" > "$LFS/etc/passwd"
        echo "$ETC_GROUP_SYSVINIT" > "$LFS/etc/group"
        echo "$ETC_FSTAB_SYSVINIT" > "$LFS/etc/fstab"
    fi

    # removed at end of build
    mkdir -p "$LFS/home/tester"
    chown 101:101 "$LFS/home/tester"

    mkdir -p "$LFS/var/log"
    touch "$LFS/var/log/"{btmp,lastlog,faillog,wtmp}
    chgrp 13 "$LFS/var/log/lastlog" # 13 == utmp
    chmod 664 "$LFS/var/log/lastlog"
    chmod 600 "$LFS/var/log/btmp"

    # LFS 12.4 Section 10.3.2
    install -m755 -d "$LFS/etc/modprobe.d"

    # install static files
    echo "$LFS_HOSTNAME" > "$LFS/etc/hostname"
    echo "$LFS_VERSION" > "$LFS/etc/lfs-release"
    local f
    for f in ./static/*; do
        install_static "$f"
    done
    if [[ -n $KERNELCONFIG ]]; then
        cp "$KERNELCONFIG" "$LFS/boot/config-$LFS_KERNEL_VERSION"
    fi

    # install templates
    for f in ./templates/*; do
        install_template "$f"
    done

    # copy sources into image
    mkdir -p "$LFS/sources"
    cp ./packages/* "$LFS/sources"

    set +x
}

download_packages() {
    local extension_dir=${1:-}
    local package_dir=$LFS_PACKAGE_DIR
    local package_list=$LFS_PACKAGE_LIST
    if [[ -n $extension_dir ]]; then
        # if an extension is being built, it will
        # override the packages and packages.sh paths
        package_dir=$extension_dir/packages
        package_list=$extension_dir/packages.sh
    fi

    if (( SKIPDOWNLOAD )); then
        log_warning "skipping package download"
        return 0
    fi

    if ! [[ -f $package_list ]]; then
        log_error "'$package_list' is missing"
        return 1
    fi

    mkdir -p "$package_dir"

    local package_urls
    package_urls=$(grep "^[^#]" < "$package_list" | cut -d"=" -f2)

    _download_url() {
        local url=${1:?_download_url(): url required}
        if ! find "$package_dir" -mindepth 1 ! -name '*.in_progress' | \
            grep "$(basename "$url")" > /dev/null; then
            if ! curl --location --silent --output "$package_dir/$(basename "$url")" "$url"; then
                log_error "failed to download '$url'"
                return 1
            fi
        else
            log_warning "already have $(basename "$url") -- skipping."
        fi
    }

    local url
    for url in $package_urls; do
        # track in-progress downloads and remove packages we failed to download in previous runs
        local dwnldfile
        dwnldfile="$package_dir/$(basename "$url")"
        local in_progress="${dwnldfile}.in_progress"
        if [[ -f $in_progress ]]; then
            log_warning "$dwnldfile appears to be incomplete -- redownloading"
            rm -f "$in_progress" "$dwnldfile"
        fi
        touch "$in_progress"
        if ! with_log "downloading $(basename "$url")" _download_url "$url"; then
            return 1
        fi
        rm "$in_progress"
    done
}

mount_image() {
    if ! check_root_user; then
        return 1
    fi

    if [[ ! -f $LFS_IMG ]]
    then
        log_error "$LFS_IMG not found -- cannot mount."
        exit 1
    fi

    # make sure everything is unmounted first
    with_log "making sure image is unmounted" unmount_image

    # attach loop device
    export LOOP
    LOOP=$(losetup -f) # export for grub.sh
    local LOOP_P1=${LOOP}p1

    with_log "attaching $LOOP" losetup -P "$LOOP" "$LFS_IMG"

    with_log "mounting $LOOP_P1 onto $LFS" mount "$LOOP_P1" "$LFS"

    # LFS 12.4 Section 7.3
    mkdir -p "$LFS"/{dev,proc,sys,run}
    with_log "mounting /dev onto $LFS/dev" mount --bind /dev "$LFS/dev"
    with_log "mounting devpts onto $LFS/dev/pts" mount -t devpts devpts -o gid=5,mode=0620 "$LFS/dev/pts"
    with_log "mounting proc onto $LFS/proc" mount -t proc proc "$LFS/proc"
    with_log "mounting sysfs onto $LFS/sys" mount -t sysfs sysfs "$LFS/sys"
    with_log "mounting tmpfs onto $LFS/run" mount -t tmpfs tmpfs "$LFS/run"

    if [[ -h "$LFS/dev/shm" ]]; then
        with_log "creating $LFS/dev/shm" install -d -m 1777 "$LFS/$(realpath /dev/shm)"
    else
        with_log "mounting tmpfs onto $LFS/dev/shm" mount -t tmpfs -o nosuid,nodev tmpfs "$LFS/dev/shm"
    fi
}

unmount_image() {
    if ! check_root_user; then
        return 1
    fi

    # unmount everything
    local MOUNTED_LOCS
    MOUNTED_LOCS=$(findmnt -R "$LFS" -o TARGET -n -l | tac)
    IFS=$'\n'
    if [[ -n $MOUNTED_LOCS ]]; then
        local loc
        for loc in $MOUNTED_LOCS; do
            with_log "unmounting $loc" umount "$loc"
        done
    fi
    unset IFS

    # detach loop device
    local ATTACHED_LOOP
    ATTACHED_LOOP=$(losetup | grep "$LFS_IMG" | awk '{print $1}')
    if [[ -n "$ATTACHED_LOOP" ]]; then
        with_log "detatching $ATTACHED_LOOP" losetup -d "$ATTACHED_LOOP"
    fi
}

build_package() {
    local phase=$1 # the phase directory where the script is located (1, 2, 3, or 4 (or 5 if building an extension))
    local script_name=$2 # the name of the script without the .sh extension
    local tar_name=$3 # the shell variable name for the tar file without the PKG_ prefix (defaults to $script_name)
    local do_chroot=$4 # whether the script should be executed using chroot
    local drop_shell=$5 # start an interactive shell instead of running the build script

    local log_file="$SCRIPT_DIR/logs/${script_name}_phase${phase}.log"
    local script_path="$SCRIPT_DIR/phase${phase}/${script_name}.sh"
    if (( phase == 5 )); then
        log_file="$EXTENSIONDIR/logs/${script_name}.log"
        script_path="$EXTENSIONDIR/scripts/${script_name}.sh"
    fi

    # ensure log dir
    mkdir -p "$(dirname "$log_file")"

    if [[ ! -f $script_path ]]; then
        log_error "'$script_path': file does not exist"
        return 1
    fi

    to_upper(){ echo "$@" | tr '[:lower:]' '[:upper:]'; }

    local pkg_var_name
    pkg_var_name="PKG_$(to_upper "$script_name")"
    if [[ $tar_name != "_" && $tar_name != "" ]]; then
        pkg_var_name="PKG_$(to_upper "$tar_name")"
    fi

    local run_dir="$LFS/sources/$script_name"

    local pkg_path
    if [[ $tar_name != "_" ]]; then
        if [[ ! -v $pkg_var_name ]] || [[ -z ${!pkg_var_name} ]]; then
            log_error "'$pkg_var_name': package variable is empty or undefined"
            return 1
        fi
        pkg_path="$LFS/sources/$(basename "${!pkg_var_name}")"
        if [[ ! -f $pkg_path ]]; then
            log_error "'$pkg_path': package does not exist"
            return 1
        fi
    fi

    rm -rf "$run_dir"
    mkdir -p "$run_dir"

    if [[ $tar_name != "_" ]]; then
        with_log "extracting $pkg_path" tar -xf "$pkg_path" -C "$run_dir" --strip-components=1 || return 1
    fi

    local build_instr
    build_instr="
        pushd sources > /dev/null
        cd '$script_name'
        set -ueExo pipefail
        $(cat "$script_path")
        popd
        rm -rf 'sources/$script_name'
    "

    pushd "$LFS" > /dev/null

    run_build() {
        if (( drop_shell )); then
            pushd "$LFS/sources/$script_name"
            set +e
            bash +h -i
            set -e
            popd
        else
            bash +h -c "$build_instr" |& { 
                {
                    (( VERBOSITY == 10 )) && tee "$log_file";
                } || cat > "$log_file";
            }
        fi
    }

    run_build_chroot() {
        if (( drop_shell )); then
            chroot "$LFS" /usr/bin/env \
                HOME=/root \
                TERM="$TERM" \
                PATH=/usr/bin:/usr/sbin \
                /usr/bin/bash -c "cd sources/$script_name && bash +h -i"
        else
            chroot "$LFS" /usr/bin/env \
                HOME=/root \
                TERM="$TERM" \
                PATH=/usr/bin:/usr/sbin \
                /usr/bin/bash +h -c "$build_instr" |& {
                    {
                        (( VERBOSITY == 10 )) && tee "$log_file"; 
                    } || cat > "$log_file";
                }
        fi
    }

    rm -f "$log_file"
    touch "$log_file"

    if (( do_chroot )); then
        if ! with_log "running phase$phase/${script_name}.sh in chroot environment" run_build_chroot; then
            tail -20 "$log_file"
            return 1
        fi
    else
        if ! with_log "running phase$phase/${script_name}.sh on host machine" run_build; then
            tail -20 "$log_file"
            return 1
        fi
    fi

    popd > /dev/null
    gzip -f "$log_file"

    return 0
}

build_phase() {
    if ! check_root_user; then
        return 1
    fi

    local phase=${1:?build_phase(): phase is required}

    if [[ -n $STARTPHASE ]]; then
        if (( phase < STARTPHASE )) || (( FOUNDSTARTPHASE && ONEOFF ))
        then
            log_warning "skipping phase $phase"
            return 0
        else
            FOUNDSTARTPHASE=1
        fi
    fi

    if [[ -n $ENDPHASE && -z $ENDPKG ]] && (( phase == ENDPHASE ))
    then
        log_warning "halting build at phase ${ENDPHASE}"
        HALTBUILD=1
        return 0
    fi

    if (( phase != 1 )) && [[ ! -f $LFS/sources/.phase$(( phase-1 )) ]]
    then
        log_error "phases preceeding phase $phase have not been built"
        return 1
    fi

    local do_chroot=0
    if (( phase > 2 ))
    then
        do_chroot=1
    fi

    local phase_dir=$SCRIPT_DIR/phase$phase
    if (( phase == 5 )); then
        # Phase 5 == a build extension
        phase_dir=$EXTENSIONDIR
    fi

    local build_order_file="$phase_dir/build_order.txt"
    local build_order_file_systemd="$phase_dir/build_order_systemd.txt"
    if (( BUILDSYSTEMD )) && [[ -f $build_order_file_systemd ]]; then
        build_order_file=$build_order_file_systemd
    fi

    local pkg_list
    pkg_list=$(grep -Ev '^[#]|^$|^ *$' "$build_order_file")
    local pkg_count
    pkg_count=$(echo "$pkg_list" | wc -l)
    mapfile -t build_order <<< "$pkg_list"

    for (( i=0;i<pkg_count;i++ )); do
        if (( FOUNDSTARTPKG && ONEOFF )); then
            # already found one-off build, just quit
            log_warning "completed one-off build of $STARTPKG phase $STARTPHASE; halting build"
            HALTBUILD=1
            return 0
        fi

        local script_name
        script_name=$(echo "${build_order[$i]}" | cut -d" " -f1)
        local tar_name
        tar_name=$(echo "${build_order[$i]}" | cut -d" " -f2)
        if [[ -z "$tar_name" ]]; then
            tar_name=$script_name
        fi

        if [[ -n $ENDPHASE && -n $ENDPKG ]] && (( phase == ENDPHASE )) && [[ $script_name == "$ENDPKG" ]]; then
            log_warning "halting build at phase ${ENDPHASE}, package ${ENDPKG}"
            HALTBUILD=1
            return 0
        fi

        if [[ -n $STARTPKG ]] && (( ! FOUNDSTARTPKG )) && [[ $STARTPKG != "$script_name" ]]; then
            log_warning "skipping $script_name phase $phase"
            continue
        else
            FOUNDSTARTPKG=1 # this is only used if STARTPHASE and STARTPKG are defined
            with_log "building $script_name phase $phase" build_package      \
                "$phase"       \
                "$script_name" \
                "$tar_name"    \
                "$do_chroot"   \
                "$DROPSHELL" || return 1
        fi
    done

    if [[ -n $STARTPKG ]] && (( STARTPHASE == phase && ! FOUNDSTARTPKG )); then
        log_error "package build '$STARTPKG' not present in phase '$STARTPHASE'"
        return 1
    fi

    touch "$LFS/sources/.phase$phase"

    return 0
}

build_extension() {
    if ! check_root_user; then
        return 1
    fi

    [[ ! -d $EXTENSIONDIR ]] &&
        log_error "extension '$EXTENSIONDIR' is not a directory, or does not exist." && return 1

    [[ ! -f "$EXTENSIONDIR/packages.sh" ]] &&
        log_error "extension '$EXTENSIONDIR' is missing a 'packages.sh' file." && return 1

    [[ ! -f "$EXTENSIONDIR/build_order.txt" ]] &&
        log_error "extension '$EXTENSIONDIR' is missing a 'build_order.txt' file." && return 1

    [[ ! -d "$EXTENSIONDIR/scripts/" ]] && 
        log_error "extension '$EXTENSIONDIR' is missing a 'scripts' directory." && return 1

    mkdir -p "$EXTENSIONDIR/"{logs,packages}

    # read in extension config.sh if present
    [[ -f "$EXTENSIONDIR/config.sh" ]] && source "$EXTENSIONDIR/config.sh"

    # read packages.sh (so the extension scripts can see them)
    source "$EXTENSIONDIR/packages.sh"

    # download extension packages
    if ! download_packages "$EXTENSIONDIR"; then
        return 1
    fi

    (( VERBOSITY == 10 )) && set -x

    # copy packages onto LFS image
    if [[ -n $(ls "$EXTENSIONDIR/packages/") ]]; then
        cp "$EXTENSIONDIR/packages/"* "$LFS/sources/"
    fi

    # install static files if present
    if [[ -d "$EXTENSIONDIR/static" ]]; then
        for f in "$EXTENSIONDIR/static/"*; do
            install_static "$f"
        done
    fi

    # install template files if present
    if [ -d "$EXTENSIONDIR/templates" ]; then
        for f in "$EXTENSIONDIR/templates/"*; do
            install_template "$f"
        done
    fi

    set +x

    # build extension
    build_phase 5 || return 1
}

install_image() {
    if ! check_root_user; then
        return 1
    fi

    if [[ ! -f $LFS_IMG ]]; then
        log_error "'$LFS_IMG' image file does not exist. Be sure to build LFS completely before attempting to install."
        return 1
    fi

    local part_prefix=""
    case "$(basename "$INSTALLTARGET")" in
      sd[a-z])
        part_prefix=""
        ;;
      nvme[0-9]n[1-9])
        part_prefix="p"
        ;;
      *)
        log_eror "unsupported device name '$INSTALLTARGET'."
        return 1
        ;;
    esac

    if ! prompt_warning "this will delete all contents of the device $INSTALLTARGET"; then
        log_warning "cancelled"
        exit 1
    fi

    # wipe beginning of device (sometimes grub-install complains about "multiple partition labels")
    with_log "wiping partition table of $INSTALLTARGET" dd if=/dev/zero of="$INSTALLTARGET" count=2048
 
    # partition the device.
    # remove spaces and comments
    local fdisk_instr
    # shellcheck disable=SC2001
    fdisk_instr=$(echo "$FDISK_INSTR" | sed 's/ *#.*//')

    if ! echo "$fdisk_instr" | fdisk "$INSTALLTARGET" |& { (( VERBOSITY == 10 )) && cat || cat > /dev/null; }
    then
        log_error "failed to format $INSTALLTARGET -- consider manually clearing $INSTALLTARGET's parition table"
        return 1
    fi

    mkdir -p "$LFS" "$INSTALL_MOUNT"

    # mount IMG file
    local loop
    loop=$(losetup -f)
    local loop_p1=${loop}p1
    losetup -P "$loop" "$LFS_IMG"

    # setup install partition
    local install_p1="${INSTALLTARGET}${part_prefix}1"
    mkfs -t "$LFS_FS_TYPE" "$install_p1" &> /dev/null
    e2label "$install_p1" "$LFS_ROOT_LABEL"

    # mount install partition
    mount "$install_p1" "$INSTALL_MOUNT"
    mount "$loop_p1" "$LFS"

    with_log "copying files" cp -r "$LFS/"* "$INSTALL_MOUNT"

    # make sure grub.cfg is pointing at the right drive
    local partuuid
    partuuid=$(lsblk -o PARTUUID "$INSTALLTARGET" | tail -1)
    sed -Ei "s/root=PARTUUID=[0-9a-z-]+/root=PARTUUID=${partuuid}/" "$INSTALL_MOUNT/boot/grub/grub.cfg"

    mount --bind /dev "$INSTALL_MOUNT/dev"
    mount --bind /dev/pts "$INSTALL_MOUNT/dev/pts"
    mount -t sysfs sysfs "$INSTALL_MOUNT/sys"

    with_log "installing GRUB -- this may take a few minutes" \
        chroot "$INSTALL_MOUNT" /usr/bin/bash -c \
            "grub-install '$INSTALLTARGET' --target i386-pc"

    with_log "unmounting $LFS_IMG" unmount_image

    log_info "installation successful"
}

clean_image() {
    if ! check_root_user; then
        return 1
    fi

    with_log "unmounting $LFS_IMG" unmount_image

    if [[ -f $LFS_IMG ]] && prompt_warning "this will delete $LFS_IMG"; then
        with_log "deleting $LFS_IMG" rm "$LFS_IMG"
    fi

    if [[ -d $SCRIPT_DIR/logs && -n $(find "$SCRIPT_DIR/logs" -mindepth 1) ]]; then
        with_log "deleting logs" rm -f "$SCRIPT_DIR/logs/"*
    fi
}

main() {
    # ###############
    # Parse arguments
    # ~~~~~~~~~~~~~~~

    cd "$SCRIPT_DIR"

    while [ $# -gt 0 ]; do
      case $1 in
        -V|--version)
          echo $LFS_VERSION
          exit
          ;;
        -v)
          VERBOSITY=3
          shift
          ;;
        -vv)
          VERBOSITY=5
          shift
          ;;
        -vvv)
          VERBOSITY=10
          shift
          ;;
        -D|--systemd)
          BUILDSYSTEMD=1
          LFS_KERNEL_SUFFIX="-systemd"
          shift
          ;;
        -e|--check)
          CHECKDEPS=1
          shift
          ;;
        -b|--build-all)
          BUILDALL=1
          shift
          ;;
        -x|--extend)
          EXTENSIONDIR=$2
          shift
          shift
          ;;
        -d|--download)
          DOWNLOAD=1
          shift
          ;;
        -s|--skip-download)
          SKIPDOWNLOAD=1
          shift
          ;;
        -i|--init)
          INIT=1
          shift
          ;;
        -t|--skip-init)
          SKIPINIT=1
          shift
          ;;
        -p|--start-phase)
          STARTPHASE=$2
          [[ -z $STARTPHASE ]] && log_error "$1 missing argument" && exit 1
          shift
          shift
          ;;
        -a|--start-package)
          STARTPKG=$2
          [[ -z $STARTPKG ]] && log_error "$1 missing argument" && exit 1
          shift
          shift
          ;;
        -o|--one-off)
          ONEOFF=1
          shift
          ;;
        -y|--end-phase)
          ENDPHASE=$2
          [[ -z $ENDPHASE ]] && log_error "$1 missing argument" && exit 1
          shift
          shift
          ;;
        -z|--end-package)
          ENDPKG=$2
          [[ -z $ENDPKG ]] && log_error "$1 missing argument" && exit 1
          shift
          shift
          ;;
        -r|--drop-shell)
          DROPSHELL=1
          shift
          ;;
        -k|--kernel-config)
          KERNELCONFIG=$2
          [[ -z $KERNELCONFIG ]] && log_error "$1 missing argument" && exit 1
          shift
          shift
          ;;
        -m|--mount)
          MOUNT=1
          shift
          ;;
        -u|--umount)
          UNMOUNT=1
          shift
          ;;
        -n|--install)
          INSTALLTARGET=$2
          [[ -z $INSTALLTARGET ]] && log_error "$1 missing argument" && exit 1
          shift
          shift
          ;;
        -c|--clean)
          CLEAN=1
          shift
          ;;
        -h|--help)
          usage
          exit
          ;;
        *)
          log_error "unknown option: $1"
          usage
          exit 1
          ;;
      esac
    done

    local opcount=0
    for op in BUILDALL CHECKDEPS DOWNLOAD INIT STARTPHASE MOUNT UNMOUNT INSTALLTARGET CLEAN; do
        op="${!op}"
        if [[ -n $op && $op != "0" ]]; then
            opcount=$((opcount+1))
        fi

        if (( opcount > 1 )); then
            log_error "too many options"
            exit 1
        fi
    done
    if (( ! opcount )); then
        log_error "must specify one of:
    -b|--build-all
    -e|--check
    -d|--download-packages
    -i|--init
    -p|--start-phase
    -m|--mount
    -u|--umount
    -n|--install
    -c|--clean"
        exit 1
    fi

    if [[ -n $STARTPHASE ]]; then
        if ! [[ $STARTPHASE =~ ^[1-5]$ ]]; then
            log_error "-p|--start-phase must specify a number between 1 and 5"
            exit 1
        elif (( STARTPHASE == 5 )) && [[ -z $EXTENSIONDIR ]]; then
            log_error "phase 5 only exists if an -x|--extend has been specified"
            exit 1
        elif [[ ! -f $LFS_IMG ]]; then
            log_error "$LFS_IMG not found -- cannot start from phase $STARTPHASE"
            exit 1
        fi
    fi

    if [[ -n $STARTPKG && -z $STARTPHASE ]]; then
        log_error "-p|--start-phase must be defined if -a|--start-package is defined"
        exit 1
    elif (( ONEOFF )) && [[ -z $STARTPHASE ]]; then
        log_error "-o|--one-off has no effect without a starting phase selected"
        exit 1
    fi

    if [[ -n $ENDPKG && -z $ENDPHASE ]]; then
        log_error "-y|--end-phase must be defined if -z|--end-package is defined"
        exit 1
    elif (( ONEOFF )) && [[ -n $ENDPHASE ]]; then
        log_error "-y|--end-phase has no effect when -o|--one-off is selected"
        exit 1
    fi

    if [[ -n $STARTPHASE && -n $ENDPHASE ]] && (( STARTPHASE > ENDPHASE )); then
        log_error "-p|--start-phase cannot be greater than -y|--end-phase is defined"
        exit 1
    fi

    if [[ -n $EXTENSIONDIR ]]; then
        if (( ! BUILDALL )) && [[ -z $STARTPHASE ]]; then
            log_error "-x|--extend has no effect without either -b|--build-all or -p|--start-phase set"
            exit 1
        elif [[ ! -d $EXTENSIONDIR ]]
        then
            log_error "'$EXTENSIONDIR' is not a directory or does not exist"
            exit 1
        fi

        # get full path to extension
        EXTENSIONDIR=$(realpath "$EXTENSIONDIR")
    fi

    trap "trap - ERR && log_error 'operation cancelled' && unmount_image &> /dev/null && exit 1" SIGINT
    trap "log_error 'operation failed' && unmount_image &> /dev/null && exit 0" ERR

    if (( CHECKDEPS )); then
        set +e
        with_log "checking dependencies" version_check
        exit
    elif (( DOWNLOAD )); then
        with_log "downloading packages" download_packages
        exit
    elif (( INIT )); then
        with_log "downloading packages" download_packages
        with_log "creating image file" init_image
        with_log "unmounting image" unmount_image
        exit
    elif (( MOUNT )); then
        with_log "mounting image" mount_image
        exit
    elif (( UNMOUNT )); then
        with_log "unmounting image" unmount_image
        exit
    elif (( CLEAN )); then
        with_log "cleaning up" clean_image
        exit
    elif [[ -n $INSTALLTARGET ]]; then
        with_log "installing image to '$INSTALLTARGET'" install_image
        exit
    fi # else BUILDALL/STARTPHASE

    build_loop() {
        local stop_phase=4
        if [[ -n $EXTENSIONDIR ]]; then
            stop_phase=5
        fi

        # vars that don't make sense to keep in config.sh
        FOUNDSTARTPHASE=0
        FOUNDSTARTPKG=0
        HALTBUILD=0

        local phase
        for ((phase=1;phase<=stop_phase;phase++ )); do
            if (( phase == 5 )); then
                if ! with_log "building extension $EXTENSIONDIR" build_extension; then
                    return 1
                fi
            else
                if ! with_log "building phase $phase" build_phase "$phase"; then
                    return 1
                fi
            fi

            # phase 3 cleanup (LFS 12.4 Section 7.13.1)
            if (( phase == 3 && (BUILDALL || STARTPHASE <= 3) )); then
                post_phase_3_cleanup() {
                    rm -rf "$LFS/usr/share/"{info,man,doc}/*
                    find "$LFS/usr/"{lib,libexec} -name \*.la -delete
                    rm -rf "$LFS/tools"
                }
                if ! with_log "post phase 3 cleanup" post_phase_3_cleanup; then
                    return 1
                fi
            fi

            if (( (ONEOFF && FOUNDSTARTPHASE) || HALTBUILD )); then
                return 0
            fi

            # phase 4 cleanup (LFS 12.4 Section 8.85)
            if (( phase == 4 && (BUILDALL || STARTPHASE <= 4) )); then
                post_phase_4_cleanup() {
                    # rm -rf "$LFS/tmp/"{*,.*} &&
                    # above produces annoying stderr output about . and ..
                    # so doing the below find cmd instead
                    find "$LFS/tmp" -mindepth 1 -delete &&
                    find "$LFS/usr/lib" "$LFS/usr/libexec" -name \*.la -delete &&
                    find "$LFS/usr" -depth -name "$LFS_TGT*" -print0 | xargs --null rm -rf &&
                    rm -rf "$LFS/home/tester" &&
                    sed -i 's/^.*tester.*$//' "$LFS/etc/"{passwd,group} ||
                    return 1
                }
                if ! with_log "post phase 4 cleanup" post_phase_4_cleanup; then
                    return 1
                fi
            fi
        done
    }

    if (( BUILDALL )); then
        with_log "downloading packages" download_packages
        with_log "creating image file" init_image
    fi
    with_log "mounting image" mount_image
    if ! with_log "building LFS $LFS_VERSION" build_loop; then
        exit 1
    fi
    with_log "unmounting image" unmount_image
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
