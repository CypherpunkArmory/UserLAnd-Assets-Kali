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
docker-compose -f build_image.yml -f $1_build.yml down
docker-compose -f build_image.yml -f $1_build.yml build
docker-compose -f build_image.yml -f $1_build.yml up --force-recreate
cat output/rootfs.tar | docker import - $IMAGE_ARCH/my_kali:latest

docker-compose -f main.yml -f $1.yml down
docker-compose -f main.yml -f $1.yml build
docker-compose -f main.yml -f $1.yml up --force-recreate
mkdir -p release
cp output/rootfs.tar.gz release/$1-rootfs.tar.gz
mkdir -p release/assets
cp assets/all/* release/assets/
rm release/assets/assets.txt
cp output/busybox release/assets/
cp output/libdisableselinux.so release/assets/
tar -czvf release/$1-assets.tar.gz -C release/assets/ .
for f in $(ls release/assets/); do echo "$f $(date +%s -r release/assets/$f) $(md5sum release/assets/$f | awk '{ print $1 }')" >> release/$1-assets.txt; done
rm -rf release/assets
