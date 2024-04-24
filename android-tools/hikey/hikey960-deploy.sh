#!/bin/bash -ex

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

#if ! [ -d ${img_dir} ]; then
#    echo "The specified path is not a directory:${img_dir}"
#    exit 1
#fi

##############common functions ###############

function check_file_existence(){
    local target_file="${1}"
    if echo "${target_file}"|grep -E "^http://|^https://"; then
        is_xz_file=false
        if wget --spider "${target_file}"; then
            return 0
        elif wget --spider "${target_file}.xz"; then
            return 0
        else
            return 1
        fi
    elif [ -f "${target_file}" ]; then
        return 0
    elif [ -f "${target_file}.xz" ]; then
        return 0
    fi
    return 1
}

function fastboot_wrapper(){
    local fastboot_cmd="${1}"
    local partition="${2}"
    local file_img="${3}"
    if [ -z "${partition}" ] || [ -z "${file_img}" ]; then
        return
    fi
    temp_file=false
    if echo "${file_img}"|grep -E "^http://|^https://"; then
        f_img_local=$(mktemp -u "/tmp/${partition}-XXX.img")
        ## + wget -c http://192.168.1.14:8000/android/lkft/lkft-aosp-main-db845c/1662/images//cache.img --progress=dot:mega -O /tmp/cache-GNu.img
        ## --2023-10-19 14:08:42--  http://192.168.1.14:8000/android/lkft/lkft-aosp-main-db845c/1662/images//cache.img
        ## Connecting to 192.168.1.14:8000... connected.
        ## HTTP request sent, awaiting response... 404 File not found
        ## 2023-10-19 14:08:42 ERROR 404: File not found.
        is_xz_file=false
        if wget --spider "${file_img}"; then
            cmd_wget="wget -c ${file_img} --progress=dot:giga -O ${f_img_local}"
        elif wget --spider "${file_img}.xz"; then
            cmd_wget="wget -c ${file_img}.xz --progress=dot:giga -O ${f_img_local}.xz"
            is_xz_file=true
        else
            echo "Neither ${file_img} nor ${file_img}.xz exists"
            return
        fi
        if ${cmd_wget}; then
            ${is_xz_file} && xz -d "${f_img_local}.xz"
            file_img="${f_img_local}"
            temp_file=true
        else
            rm -f "${f_img_local}"
            return
        fi
    fi

    if [ -f "${file_img}" ]; then
        :
    elif [ -f "${file_img}.xz" ]; then
        f_img_local=$(mktemp -u "/tmp/${partition}-XXX.img")
        if xz -c -d "${file_img}.xz" >"${f_img_local}"; then
            temp_file=true
            file_img="${f_img_local}"
        else
            return
        fi
    else
        echo "Neither ${file_img} nor ${file_img}.xz exists"
        return
    fi

    echo "======= Flash ${partition} partition with file $file_img =============="
    #/SATA3/nougat/out/host/linux-x86/bin/fastboot flash -w ${partition} ${file_img}
    if [ "X${fastboot_cmd}" = "Xboot" ]; then
        fastboot "${fastboot_cmd}" "${file_img}"
        ret=$?
    else
        fastboot "${fastboot_cmd}" "${partition}" "${file_img}"
        ret=$?
    fi
    if [ $ret -ne 0 ]; then
        echo "Failed to deploy ${file_img}"
        exit 1
    elif ${temp_file}; then
        rm "${file_img}"
    fi
    # sleep 2 after flash
    sleep 2
}

function flash_image(){
    local partition="${1}"
    local file_img="${2}"
    fastboot_wrapper "flash" "${partition}" "${file_img}"
}

function boot_image(){
    local file_img="${1}"
    fastboot_wrapper "boot" "boot" "${file_img}"
}

#### common functions ###################
if check_file_existence "${img_dir}/prm_ptable.img"; then
    flash_image ptable "${img_dir}/prm_ptable.img"
else
    flash_image ptable ${dir_parent}/prm_ptable-hikey960-super.img
fi
flash_image boot ${img_dir}/boot.img
#flash_image dts "${img_dir}"/dt.img
flash_image super ${img_dir}/super.img
flash_image userdata ${img_dir}/userdata.img
fastboot format cache
#fastboot reboot
boot_image ${img_dir}/boot.img
