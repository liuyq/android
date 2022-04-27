#!/bin/bash

local_android_serial="616A34F301931D53"
local_android_product="hikey960"

if adb devices|grep ${local_android_serial}; then
    adb -s ${local_android_serial} reboot bootloader
    sleep 5
    fastboot devices
    sleep 3
fi
num_fastboot_devices=$(fastboot devices|wc -l)
if [ ${num_fastboot_devices} -eq 0 ]; then
    echo "No fastboot devices available, please check and try again"
    export ANDROID_SERIAL="${local_android_serial}"
elif [ ${num_fastboot_devices} -ne 1 ] && [ -z "${ANDROID_SERIAL}" ]; then
    # for local multiple devices support
    export ANDROID_SERIAL="${local_android_serial}"
elif [ ${num_fastboot_devices} -eq 1 ] && [ -z "${ANDROID_SERIAL}" ]; then
    device_serial=$(fastboot devices|awk '{print $1}')
    export ANDROID_SERIAL="${device_serial}"
fi

product=$(fastboot getvar product 2>&1 |grep product|awk '{print $2}')
if [ "X${product}" != "X${local_android_product}" ]; then
    echo "This is not a ${local_android_product} board: ${product}"
    exit 1
fi

dir_parent=$(cd $(dirname ${0}); pwd)

img_dir=${1}
if [ -z "${img_dir}" ]; then
    img_dir="out/target/product/hikey960"
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

if [ -f ${img_dir}/prm_ptable.img ]; then
    flash_image ptable ${img_dir}/prm_ptable.img
elif [ -f ${img_dir}/super.img ]; then
    flash_image ptable ${dir_parent}/prm_ptable-hikey960-super.img
else
    flash_image ptable ${dir_parent}/prm_ptable-hikey960-system.img
fi
flash_image boot ${img_dir}/boot.img
flash_image dts "${img_dir}"/dt.img
if [ -f ${img_dir}/super.img ]; then
    flash_image super ${img_dir}/super.img
else
    flash_image system ${img_dir}/system.img
    flash_image vendor ${img_dir}/vendor.img
fi
flash_image userdata ${img_dir}/userdata.img
fastboot format cache
fastboot reboot
