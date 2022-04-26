# MyLFS
It's a giant bash script to build my own Linux distro based on LFS + BLFS. Pronounce it in whatever way seems best to you.

## How To Use
Basically, just run `sudo ./build.sh` and then stare at your terminal for several hours. Maybe meditate on life or something while you wait. Or maybe clean your room or do your dishes finally. I don't know. Do whatever you want. Maybe by the end of the script, you'll realize why you love linux so much: you love it because it is *hard*. Just like going to the moon, god dammit.

```
$ sudo ./build.sh --help

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
```
And that's all the help you're getting.
