# LFS Build Configuration
# ~~~~~~~~~~~~~~~~~~~~~~~
# This file should be sourced by the other scripts
# that need these variables.

function get_script_dir {
    SOURCE=$1

    if [ -z "$SOURCE" ]
    then
        echo "ERROR: get_script_dir missing BASH_SOURCE parameter."
        exit -1
    fi

    echo "$(cd -- "$(dirname -- "$SOURCE")" &> /dev/null && pwd)"
}

export -f get_script_dir
export PACKAGE_LIST=$(get_script_dir $BASH_SOURCE)/pkgs.sh
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export LFS_FS=ext4
export LFS_IMG=$(get_script_dir $BASH_SOURCE)/lfs.img
export LFS_IMG_SIZE=$((10*1024*1024*1024)) # 10 GiB
export LFS_USER=lfs

KEYS="PACKAGE_LIST LFS LFS_TGT LFS_FS LFS_IMG LFS_IMG_SIZE LFS_USER"

for KEY in $KEYS
do
    if [ -z ${!KEY} ]
    then
        echo "ERROR: '$KEY' config is not set."
        exit -1
    fi
done

