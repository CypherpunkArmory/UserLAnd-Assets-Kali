#!/bin/bash

export DEBOOTSTRAP_DIR=output/debootstrap
export ARCH_DIR=output
export ROOTFS_DIR=output/rootfs

case "$1" in
    arm32v7) export DEBOOTSTRAP_ARCH=armhf
        ;;
    arm64v8) export DEBOOTSTRAP_ARCH=arm64
        ;;
    i386) export DEBOOTSTRAP_ARCH=i386
        ;;
    amd64) export DEBOOTSTRAP_ARCH=amd64
        ;;
    *) echo "unsupported arch: $1"
        exit
        ;;
esac

mkdir -p $ARCH_DIR
rm -rf $ROOTFS_DIR
mkdir -p $ROOTFS_DIR
rm -rf $DEBOOTSTRAP_DIR
mkdir -p $DEBOOTSTRAP_DIR

DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C apt update
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C apt install -y make git makedev wget
wget -O output/kali-archive-keyring_2018.1_all.deb http://http.kali.org/pool/main/k/kali-archive-keyring/kali-archive-keyring_2018.1_all.deb
dpkg -i output/kali-archive-keyring_2018.1_all.deb
git clone git://git.kali.org/packages/debootstrap.git $DEBOOTSTRAP_DIR
make -C $DEBOOTSTRAP_DIR devices.tar.gz
$DEBOOTSTRAP_DIR/debootstrap --foreign --arch=$DEBOOTSTRAP_ARCH --variant=minbase --include=kali-archive-keyring,perl kali-rolling $ROOTFS_DIR http://http.kali.org/kali
case "$1" in
    arm) cp qemu-arm-static $ROOTFS_DIR/usr/bin/
        ;;
    arm64) cp qemu-aarch64-static $ROOTFS_DIR/usr/bin/
        ;;
esac
unset DEBOOTSTRAP_DIR
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot $ROOTFS_DIR /debootstrap/debootstrap --second-stage

echo "127.0.0.1 localhost" > $ROOTFS_DIR/etc/hosts
echo "nameserver 8.8.8.8" > $ROOTFS_DIR/etc/resolv.conf
echo "nameserver 8.8.4.4" >> $ROOTFS_DIR/etc/resolv.conf

echo "#!/bin/sh" > $ROOTFS_DIR/etc/profile.d/userland.sh
echo "unset LD_PRELOAD" >> $ROOTFS_DIR/etc/profile.d/userland.sh
echo "unset LD_LIBRARY_PATH" >> $ROOTFS_DIR/etc/profile.d/userland.sh
echo "export LIBGL_ALWAYS_SOFTWARE=1" >> $ROOTFS_DIR/etc/profile.d/userland.sh
chmod +x $ROOTFS_DIR/etc/profile.d/userland.sh

echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" > $ROOTFS_DIR/etc/apt/sources.list
echo "#deb-src http://http.kali.org/kali kali-rolling contrib non-free" >> $ROOTFS_DIR/etc/apt/sources.list

tar --exclude='dev/*' -cvf $ARCH_DIR/rootfs.tar -C $ROOTFS_DIR .
