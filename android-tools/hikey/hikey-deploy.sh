#!/bin/bash


product=$(fastboot getvar product 2>&1 |grep product|awk '{print $2}')
if [ "X${product}" != "Xhikey" ]; then
    echo "This is not a hikey board: ${product}"
    exit 1
fi

img_dir=${1}
if [ -z "${img_dir}" ]; then
    img_dir="out/target/product/hikey"
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

#flash_image fastboot "${FIRMWARE_DIR}"/fip.bin
#flash_image boot ${img_dir}/boot_fat.uefi.img
flash_image boot ${img_dir}/boot.img
flash_image system ${img_dir}/system.img
flash_image vendor ${img_dir}/vendor.img
flash_image cache ${img_dir}/cache.img
flash_image userdata ${img_dir}/userdata.img
#fastboot flash -S 256M userdata ${img_dir}/userdata.img
#fastboot reboot
#fastboot continue
fastboot boot ${img_dir}/boot.img
