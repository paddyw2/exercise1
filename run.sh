# exit if any command fails, but not pipelines
set -e

# toggle busybox vs. simple init
USE_BUSYBOX=false

DISPLAY_MSG_SECONDS=2
IMAGE_DIRECTORY=new_image
ROOTFS_SUB_DIRECTORY=rootfs
INITRD_NAME=initrd.img
SIMPLE_INIT_MSG="hello world"

BUSYBOX_SOURCE=https://busybox.net/downloads/busybox-1.36.1.tar.bz2
LINUX_KERNEL_SOURCE=https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.3.12.tar.xz
ARCH=x86_64
KERNEL_PATH=linux/arch/$ARCH/boot/bzImage

echo "Creating image directory..."
rm -rf $IMAGE_DIRECTORY; mkdir -p $IMAGE_DIRECTORY
cd $IMAGE_DIRECTORY

echo "Creating empty init ramdisk image..."
dd if=/dev/zero of=$INITRD_NAME bs=100M count=1

echo "Formatting as mkfs.ext4..."
mkfs.ext4 $INITRD_NAME

echo "Creating rootfs and mounting..."
mkdir -p $ROOTFS_SUB_DIRECTORY
mount $INITRD_NAME $ROOTFS_SUB_DIRECTORY

echo "Changing into rootfs..."
cd $ROOTFS_SUB_DIRECTORY
FULL_ROOTFS_PATH=$PWD

echo "Copying rootfs init..."
if [[ $USE_BUSYBOX == "true" ]]; then
    cd ../../
    if [[ ! -d "busybox" ]]; then
        echo "Busybox not found, downloading and compiling source..."
        wget $BUSYBOX_SOURCE -O busybox.tar.bz
        tar -xf busybox.tar.bz --one-top-level=busybox --strip-components=1
        cd busybox
        # enable static build without interactive menu
        make defconfig
        sed -i "s/# CONFIG_STATIC.*/CONFIG_STATIC=y/g" .config
        make -j$(nproc)
        cd ../
    else
        echo "Busybox already exists..."
    fi
    echo "Assuming busybox has already been compiled..."
    echo "Installing busybox source to rootfs..."
    cd busybox
    make CONFIG_PREFIX=$FULL_ROOTFS_PATH install
    echo "Changing back into to rootfs..."
    cd $FULL_ROOTFS_PATH
else
    echo "No busybox configured, creating simple init file..."
    echo '#include <stdio.h>
    #include <unistd.h>

    int main() {
        printf("'$SIMPLE_INIT_MSG'\n");
        while (1) {
            sleep(2);
        }
    }' > init.c

    echo "Compiling init file..."
    gcc -static -o init init.c
    mkdir bin
    cp init bin/sh
fi

echo "Leaving rootfs directory and unmounting..."
cd ../
umount $ROOTFS_SUB_DIRECTORY

echo "Leaving image directory..."
cd ..

echo "Checking for kernel..."
if [[ ! -d "linux" ]]; then
    echo "Fetching linux kernel..."
    wget $LINUX_KERNEL_SOURCE -O linux.tar.xz
    tar -xf linux.tar.xz --one-top-level=linux --strip-components=1
    cd linux
    make defconfig
    make kvm_guest.config
    make -j$(nproc)
    cd ../
else
    echo "Kernel already exists..."
fi

echo "Assuming a linux kernel exists under ${KERNEL_PATH}..."
echo "Running QEMU with curses in ${DISPLAY_MSG_SECONDS} seconds - to quit type ESC then 2 very quickly, then type 'quit'"
sleep $DISPLAY_MSG_SECONDS
qemu-system-x86_64 -kernel $KERNEL_PATH -hda $IMAGE_DIRECTORY/$INITRD_NAME --append "root=/dev/sda init=/bin/sh" -m 512 -display curses
