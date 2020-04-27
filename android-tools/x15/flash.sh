#!/bin/bash

img_dir=${1}
if [ -z "${img_dir}" ]; then
    img_dir="out/target/product/am57xevm"
fi
if [ ! -d "${img_dir}" ]; then
    img_dir="out/target/product/beagle_x15"
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

#fastboot erase environment
#fastboot oem format
#flash_image xloader ${img_dir}/MLO
#flash_image bootloader ${img_dir}/u-boot.img
#flash_image environment ${img_dir}/am57xx-evm-reva3.dtb
#flash_image recovery ${img_dir}/recovery.img
#flash_image boot ${img_dir}/boot.img
flash_image boot_a ${img_dir}/boot.img
flash_image boot_b ${img_dir}/boot.img
flash_image dtbo_a ${img_dir}/dtbo.img
flash_image dtbo_b ${img_dir}/dtbo.img
flash_image vbmeta_a ${img_dir}/vbmeta.img
flash_image vbmeta_b ${img_dir}/vbmeta.img
flash_image recovery ${img_dir}/recovery.img
flash_image super ${img_dir}/super.img
flash_image userdata ${img_dir}/userdata.img
fastboot reboot

exit 0

reset or fastboot reboot
=> fastboot 0 # operate on sdcard?
$ fastboot flash xloader MLO # flash MLO to the partition
$ fastboot flash bootloader u-boot.img # flash u-boot.img to the partition
$ fastboot reboot
=> env default -f -a # load the all the defined environments
=> setenv partitions $partitions_android # set partitions environment with the value in partitions_android environment
=> env save # save change on partitions environment
=> fastboot 1 # boot from emmc
$ fastboot oem format # recreate the parititons again
$ fastboot flash boot boot_fit.img # flash other images
$ fastboot flash recovery recovery.img
$ fastboot flash vendor vendor.img
$ fastboot flash system system.img
$ fastboot flash userdata userdata.img
$ fastboot reboot
=> setenv bootargs "androidboot.serialno=${serial#} console=ttyS2,115200 androidboot.console=ttyS2 androidboot.hardware=beagle_x15board"
=> setenv bootargs "androidboot.serialno=${serial#} console=ttyS2,115200 androidboot.console=ttyS2 androidboot.hardware=am57xevmboard"
=> run findfdt
=> run emmc_android_boot
=> part list mmc 1 # list partitions for mmc 1

####
fastboot flash boot_a boot.img
fastboot flash boot_b boot.img
fastboot flash dtbo_a dtbo.img
fastboot flash dtbo_b dtbo.img
fastboot flash vbmeta_a vbmeta.img
fastboot flash vbmeta_b vbmeta.img
fastboot flash recovery recovery.img
fastboot flash super super.img
fastboot flash userdata userdata.img
fastboot reboot

# "card voltage select 0" usually means loose connection
# erase emmc:
=> mmc dev 1 0
=> mmc rescan
=> mmc erase 0 0x400
=> mmc erase 0 0x4000
=> mmc erase 0 0x40000
=> mmc erase 0 0x400000
# mmc dev 0 is sdcard
# dev 1 is emmc .
