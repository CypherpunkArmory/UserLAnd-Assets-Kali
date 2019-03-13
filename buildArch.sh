#!/bin/bash

case "$1" in
    arm) export IMAGE_ARCH=arm32v7
        ;;
    arm64) export IMAGE_ARCH=arm64v8
        ;;
    x86) export IMAGE_ARCH=i386
        ;;
    x86_64) export IMAGE_ARCH=amd64
        ;;
    *) echo "unsupported arch"
        exit
        ;;
esac
docker-compose -f build_image.yml down
docker-compose -f build_image.yml build
docker-compose -f build_image.yml up
cat output/rootfs.tar | docker import - $IMAGE_ARCH/my_kali:latest

docker-compose -f kali.yml -f $1.yml down
docker-compose -f kali.yml -f $1.yml build
docker-compose -f kali.yml -f $1.yml up
mkdir -p release
cp output/rootfs.tar.gz release/$1-rootfs.tar.gz
mkdir -p release/assets
cp assets/* release/assets/
cp output/busybox release/assets/
cp output/libdisableselinux.so release/assets/
tar -czvf release/$1-assets.tar.gz -C release/assets/ .
rm -rf release/assets
