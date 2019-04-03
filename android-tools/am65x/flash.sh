#!/bin/bash

img_dir=${1}
if [ -z "${img_dir}" ]; then
    img_dir="out/target/product/am65xevm"
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

#fastboot oem format
#flash_image tiboot3 ${img_dir}/tiboot3.bin
#flash_image flash bootloader ${img_dir}/bootloader.img
#flash_image recovery ${img_dir}/recovery.img
flash_image boot ${img_dir}/boot_fit.img
flash_image system ${img_dir}/system.img
flash_image userdata ${img_dir}/userdata.img
flash_image vendor ${img_dir}/vendor.img
fastboot reboot

exit 0
http://git.ti.com/cgit/cgit.cgi/ti-u-boot/ti-u-boot.git/tree/board/ti/am65x/README?h=ti-u-boot-2019.01
https://wiki.linaro.org/Boards/AM65xEVM#Obtaining_and_Building_the_Software
1. booting from eMMC
    SW2[0:3] = 0000
    SW3[0:3] = 0110
    SW4[0:1] = 00
2. booting from sdcard:
    SW2[0:3] = 0010
    SW3[0:3] = 0110
    SW4[0:1] = 11

3. firmware update on u-boot shell:
    => env default -f -a
    => setenv partitions $partitions_android
    => env save
    => fastboot 0
4.firmware update on host with fastboot
    $ fastboot oem format
    $ fastboot flash tiboot3 tiboot3.bin
    $ fastboot flash bootloader bootloader.img
    $ fastboot flash boot boot_fit.img
    $ fastboot flash system system.img
    $ fastboot flash vendor vendor.img
    $ fastboot flash userdata userdata.img
