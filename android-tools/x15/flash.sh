#!/bin/bash

img_dir=${1}
if [ -z "${img_dir}" ]; then
    img_dir="out/target/product/am57xevm"
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

    if [ ! -f "${file_img}" ]; then
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
    sleep 5
}

fastboot erase environment
fastboot oem format
flash_image xloader ${img_dir}/MLO
flash_image bootloader ${img_dir}/u-boot.img
#flash_image environment ${img_dir}/am57xx-evm-reva3.dtb
#flash_image recovery ${img_dir}/recovery.img
#flash_image boot ${img_dir}/boot.img
flash_image boot ${img_dir}/boot_fit.img
flash_image system ${img_dir}/system.img
flash_image cache ${img_dir}/cache.img
flash_image userdata ${img_dir}/userdata.img
flash_image vendor ${img_dir}/vendor.img
fastboot reboot
