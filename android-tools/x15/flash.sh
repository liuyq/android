#!/bin/bash
# https://wiki-archive.linaro.org/Boards/BeagleBoard-X15
# https://linaro.atlassian.net/wiki/spaces/CTT/pages/25111140766/BeagleBoard+X15

local_android_serial="0e005017394200e2"
local_android_product="am57xx_evm_reva3"

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
# echo 0x10 >/sys/module/drm/parameters/debug
#    Bit 0 (0x01)  will enable CORE messages (drm core code)
#    Bit 1 (0x02)  will enable DRIVER messages (drm controller code)
#    Bit 2 (0x04)  will enable KMS messages (modesetting code)
#    Bit 3 (0x08)  will enable PRIME messages (prime code)
#    Bit 4 (0x10)  will enable ATOMIC messages (atomic code)
#    Bit 5 (0x20)  will enable VBL messages (vblank code)
#    Bit 7 (0x80)  will enable LEASE messages (leasing code)
#    Bit 8 (0x100) will enable DP messages (displayport code)
#    module_param_named(debug, drm_debug, int, 0600);
#    drivers/gpu/drm/drm_drv.c
#
# echo 8 > /proc/sys/kernel/printk
# The first value in our output is the current console_loglevel. This is the information we were looking for: the value, 4 in this case, represents the log level currently used. As said before this means that only messages adopting a severity level higher than it, will be displayed on the console.
# The second value in the output represents the default_message_loglevel. This value is automatically used for messages without a specific log level: if a message is not associated with a log level, this one will be used for it.
# The third value in the output reports the minimum_console_loglevel status. It indicates the minimum loglevel which can be used for console_loglevel. The level here used it’s 1, the highest.
# Finally, the last value represents the default_console_loglevel, which is the default loglevel used for console_loglevel at boot time.

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

#fastboot erase environment
#fastboot oem format
#flash_image xloader ${img_dir}/MLO
#flash_image bootloader ${img_dir}/u-boot.img
#flash_image environment ${img_dir}/am57xx-evm-reva3.dtb
#flash_image recovery ${img_dir}/recovery.img
#flash_image boot ${img_dir}/boot.img
flash_image boot_a ${img_dir}/boot.img
flash_image boot_b ${img_dir}/boot.img
## NOTE: falsh of the dtbo_a/b partitions would cause the board failed to boot
## and need to reflash the u-boot to recover
#flash_image dtbo_a ${img_dir}/dtbo.img
#flash_image dtbo_b ${img_dir}/dtbo.img
flash_image vbmeta_a ${img_dir}/vbmeta.img
flash_image vbmeta_b ${img_dir}/vbmeta.img
flash_image recovery ${img_dir}/recovery.img
flash_image super ${img_dir}/super.img
flash_image userdata ${img_dir}/userdata.img
# format would cause error of "FAILED (remote: failed to set partition)"
fastboot erase metadata
fastboot erase misc
sleep 5
fastboot reboot
sleep 5
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
fastboot erase metadata
fastboot erase misc
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
