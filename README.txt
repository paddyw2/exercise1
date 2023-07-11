To run:

Create an empty directory, change into it, and run:

`sudo bash run.sh`

Rerunning the script will reuse compiled binaries.

To rerun the script from scratch, remove the parent directory and repeat instructions.

Optional configuration:
 - set USE_BUSYBOX=true inside the script to download, compile, and boot with busybox

Requirements:
 - QEMU (qemu-kvm)
 - internet connection
 - user has superuser privileges
 - kernel build tools (flex, bison, build-essential, libssl-dev, libelf-dev)

Assumptions:
 - kernel version 6.3.12 is acceptable
 - architecture is x86_64
 - "hello world" message is only requirement on boot
 - a running shell (i.e. busybox) is equivalent to "a fully bootable filesystem"
 - the user is able to install script requirements

Tested on:
 - Fedora 38
 - Ubuntu 22.04.2 (live server)
