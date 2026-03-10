# MyLFS
It's a giant bash script that builds Linux From Scratch.

If you don't know what this is, or haven't built Linux From Scratch on your own before, you should go through the LFS [book](https://linuxfromscratch.org) before using this script. I have been careful to leave some comments throughout the script indicating the section of the book that a particular part of the script comes from, although most sections are not marked. For example, you might see "LFS 12.4 Section 4.2". For someone wanting to understand this script while going through the book, paying attention to these may come in handy.

This is a script that I wrote for myself and for my own use, but I encourage others to fork this repository and either craft their own versions, or submit PRs to this one.

## How To Use
Consult the `mylfs.sh` help message to get a full picture of its features:
```
$ ./mylfs.sh --help
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
```

## How It Works

The script builds LFS by completing the following steps:


1. Download package source code and save to the `./packages/` directory.


2. Create a 10 gigabyte IMG file called `lfs.img`. This will serve as a virtual hard drive on which to build LFS.


3. "Attach" the IMG file as a loop device using `losetup`. This way, the host machine can operate on the IMG file as if it were a physical storage device.


4. Partition the IMG file via the loop device we've created, put an ext4 filesystem on it, then add a basic directory structure and some config files (such as /boot/grub/grub.cfg etc).


5. Build initial cross compilation tools. This corresponds to chapter 5 in the LFS book, and "phase 1" of the script.


6. Begin to build tools required for minimal chroot environment. (chapter 6/phase 2)


7. Enter chroot environment, and build remaining tools needed to build the entire LFS system. (chapter 7/phase 3)


8. Build the entire LFS system from within chroot envirnment, including the kernel, GRUB, and others. (chapter 8+/phase 4)


That's it.


## Examples
If something breaks over the course of the build, you can examine the build logs in the aptly named `logs` directory. If you discover the source of the breakage and manage to fix it, you can start the script up again from where you left off using the `--start-phase <phase-number>` and `--start-package <package-name>` commands.


For example, say the GRUB build in phase 4 broke:
```sh
sudo ./mylfs.sh --start-phase 4 --start-package grub
```
This will start the script up again at the phase 4 GRUB build, and continue on to the remaining packages.


Another example. Say you just changed your kernel config file a bit and need to recompile:
```sh
sudo ./mylfs.sh --start-phase 4 --start-package linux --one-off
```
The `--one-off` flag tells the script to exit once the starting package has been completed.


The real magic of MyLFS is that you can apply "extensions" to the script in order to automatically customize your LFS system.
```sh
sudo ./mylfs.sh --build-all --extend ./example_extension
```
Details on how extensions work can be found in `example_extension/README`.


If you want to poke around inside the image file without booting into it, you can simply use the `--mount` command like so:
```sh
sudo ./mylfs.sh --mount
```
This will mount the root partition of the IMG file under `./mnt/lfs` (i.e. not `/mnt` under the root directory). When you're done, you can unmount with the following:
```sh
sudo ./mylfs.sh --umount
```  

If you want to install the LFS IMG file onto a drive of some kind, use:
```sh
sudo ./mylfs.sh --install /dev/<devname>
```


Finally, to clean your workspace:
```sh
sudo ./mylfs.sh --clean
```
This will unmount the IMG file (if it is mounted), delete it, and delete the logs under `./logs/`. It will not delete the cached package archives under `./packages/`, but if you really want to do that you can easily `rm -f ./packages/*`.  


## Booting
So far, I have managed to boot the IMG file using QEMU (see the [runqemu.sh](runqemu.sh) script) and on bare metal using a flash drive. I have not been able to boot it up on a VM yet.

I have also been able to get the LFS.img file to boot in Proxmox 9.1.4, as follows:

Create a new VM in Proxmox. Configure the VM as normal, but do not attach a disk.

Upload or otherwise transfer the .img file to the Proxmox host, to one of the stoarge ids avaialable. I used:

```sh
scp lfs.img root@<proxmoxIP>:/<storage_id>
```

Next, run
```sh
qm importdisk <VMID> path/to/lfs.img <storage_id>
```

VMID is the VM ID of the newly created machine. storage_id is the name of the storage you transferred the lfs.img file to.

Then go to the VM hardware section for the new VM; there should be a disk at the bottom of the list that says 'unused' or similar. Double-
click it and add it to the VM.

Finally, go to the options section for the new VM, and make sure the new disk is added to the boot order, and start up your VM.
