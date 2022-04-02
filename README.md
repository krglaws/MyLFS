# MyLFS
It's a giant bash script to build my own Linux distro based on LFS + BLFS. Pronounce it in whatever way seems best to you.

## How To Use
Basically, just run `sudo ./build.sh` and then stare at your terminal for several hours. Maybe meditate on life or something while you wait. Or maybe clean your room or do your dishes finally. I don't know. Do whatever you want. Maybe by the end of the script, you'll realize why you love linux so much: you love it because it is *hard*. Just like going to the moon, god dammit.

```sh
$ sudo ./build.sh --help
Welcome to MyLFS.
     options:
         -p|--start-phase
         -a|--start-package  Select a phase and optionally a package
                             within that phase to start building from.
                             These options are only available if the preceeding
                             phases have been completed. They should really only
                             be used when something broke during a build, and you
                             don\'t want to start from the beginning again.

         -o|--one-off        Only build the specified phase/package.

         -k|--kernel-config  Optional path to kernel config file to use during linux
                             build.

         -m|--mount
         -u|--umount         These options will mount or unmount the disk image to the
                             filesystem, and then exit the script immediately.
                             You should be sure to unmount prior to running any part of
                             the build, since the image will be automatically mounted
                             and then unmounted at the end.

         -c|--clean          This will unmount and delete the image, and clear the
                             logs.

         -h|--help           Show this message.
```
And that's all the help you're getting.
