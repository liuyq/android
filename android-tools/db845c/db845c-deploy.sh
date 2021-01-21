#!/bin/bash

img_dir=${1}
if [ -z "${img_dir}" ]; then
    img_dir="out/target/product/db845c"
    FIRMWARE_DIR="out/dist"
else
    FIRMWARE_DIR="${img_dir}"
fi

if ! [ -d ${img_dir} ]; then
    echo "The specified path is not a directory:${img_dir}"
    exit 1
fi

function flash_image(){
    local partition=$1
    local file_img=$2
    if [ -z "${partition}" ] || [ -z "${file_img}" ]; then
        return
    fi
    if [ ! -e "${file_img}" ]; then
        echo "${file_img} does not exist"
        return
    fi

    echo "======= Flash ${partition} partition with file $file_img =============="
    #/SATA3/nougat/out/host/linux-x86/bin/fastboot flash -w ${partition} ${file_img}
    fastboot flash ${partition} ${file_img}
    if [ $? -ne 0 ]; then
        echo "Failed to deploy ${file_img}"
        exit 1
    fi
    # sleep 2 after flash
    sleep 2
}

flash_image boot ${img_dir}/boot.img
flash_image super ${img_dir}/super.img
flash_image userdata ${img_dir}/userdata.img
flash_image cache ${img_dir}/cache.img
flash_image vendor_boot ${img_dir}/vendor_boot.img
fastboot reboot
