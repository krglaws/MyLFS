#!/usr/bin/bash
set -e

source ./config.sh

# create user + group if not present
if [ -z "$(getent group $LFS_USR)" ]
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

echo "Checking dependency versions..."
./check_dep_versions.sh
echo "Done."

echo "Building image..."
./build_img.sh
echo "Done."

echo "Starting system build..."
chown $LFS_USER $LFS
sudo -u $LFS_USER ./build_packages.sh
echo "Done."

