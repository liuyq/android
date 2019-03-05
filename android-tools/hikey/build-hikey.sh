#!/bin/bash -ex

AOSP_ROOT=$(cd $(dirname $0); pwd)

CPUS=$(nproc)

TOOLCHAIN=clang-r346389c

CMDLINE="console=ttyAMA3,115200 androidboot.console=ttyAMA3"
CMDLINE="${CMDLINE} androidboot.hardware=hikey firmware_class.path=/vendor/firmware efi=noruntime"
CMDLINE="${CMDLINE} init=/init androidboot.boot_devices=soc/f723d000.dwmmc0"
CMDLINE="${CMDLINE} printk.devkmsg=on buildvariant=userdebug"
CMDLINE_4_19=${CMDLINE}

# common for 4.9 and 4.14
# set verity and system-as-root kernel boot parameters for 4.14 and 4.9
CMDLINE="${CMDLINE} overlay_mgr.overlay_dt_entry=hardware_cfg_enable_android_fstab_v2"
CMDLINE="${CMDLINE} rootwait ro root=/dev/dm-0"
CMDLINE="${CMDLINE} dm=\"system none ro,0 1 android-verity 179:9\""
CMDLINE="${CMDLINE} veritykeyid=id:7e4333f9bba00adfe0ede979e28ed1920492b40f"
CMDLINE_4_14=${CMDLINE}
CMDLINE_4_9=${CMDLINE}

# KERNEL_VERBOSE='V=1'
# CLANG_OPT="CC=${KERNEL_CROSS_COMPILE_CLANG} HOSTCC=${KERNEL_CROSS_COMPILE_CLANG} CLANG_TRIPLE=aarch64-linux-gnu-"
# build_kernel "${KERNEL_SRC}" \
#              "${ABS_KERNEL_OUT}" \
#              "${ARCH}" \
#              "${KERNEL_CONFIG}" \
#              "${KERNEL_CROSS_COMPILE}" \
#              "${KERNEL_MAKE_TARGETS}" \
#              "${CLANG_OPT}"
function build_kernel(){
    local KERNEL_SRC=$1 && shift
    local ABS_KERNEL_OUT=$1 && shift
    local ARCH=$1 && shift
    local KERNEL_CONFIG=${KERNEL_SRC}/arch/${ARCH}/configs/${1} && shift
    local KERNEL_CROSS_COMPILE=$1 && shift
    local KERNEL_MAKE_TARGETS=$1 && shift
    local CLANG_OPT=$1 && shift

    make -C ${KERNEL_SRC} \
         O=${ABS_KERNEL_OUT} \
         mrproper

    cd ${KERNEL_SRC} && \
        KCONFIG_CONFIG=${ABS_KERNEL_OUT}/.merged.config ./scripts/kconfig/merge_config.sh -m ${KERNEL_CONFIG} && \
        cd -
    make -j1 ${KERNEL_VERBOSE} \
        ARCH=${ARCH} \
        -C ${KERNEL_SRC} \
        O=${ABS_KERNEL_OUT} \
        CROSS_COMPILE="${KERNEL_CROSS_COMPILE}" \
        KCONFIG_ALLCONFIG=${ABS_KERNEL_OUT}/.merged.config alldefconfig

    make -j${CPUS} ${KERNEL_VERBOSE} \
        ARCH=${ARCH} \
        -C ${KERNEL_SRC} \
        O=${ABS_KERNEL_OUT} \
        ${CLANG_OPT} \
        CROSS_COMPILE="${KERNEL_CROSS_COMPILE}" \
        -s ${KERNEL_MAKE_TARGETS}
}

function build_hikey_bootimg(){
    local KERNEL_VER=$1
    local KERNEL_CMDLINE=$2


    KERNEL_SRC=${AOSP_ROOT}/kernel/linaro/hisilicon-${KERNEL_VER}/
    ABS_KERNEL_OUT=${AOSP_ROOT}/out/target/product/hikey/obj/kernel-${KERNEL_VER}
    ARCH=arm64
    KERNEL_CONFIG=hikey_defconfig
    KERNEL_CROSS_COMPILE=${AOSP_ROOT}/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
    KERNEL_MAKE_TARGETS=Image.gz-dtb
    KERNEL_CROSS_COMPILE_CLANG=${AOSP_ROOT}/prebuilts/clang/host/linux-x86/${TOOLCHAIN}/bin/clang
    CLANG_OPT="CC=${KERNEL_CROSS_COMPILE_CLANG} HOSTCC=${KERNEL_CROSS_COMPILE_CLANG} CLANG_TRIPLE=aarch64-linux-gnu-"

    build_kernel "${KERNEL_SRC}" \
                    "${ABS_KERNEL_OUT}" \
                    "${ARCH}" \
                    "${KERNEL_CONFIG}" \
                    "${KERNEL_CROSS_COMPILE}" \
                    "${KERNEL_MAKE_TARGETS}" \
                    "${CLANG_OPT}"


    KERNEL_DESCRIBE=$(cd ${KERNEL_SRC} && git rev-parse --short HEAD)

    if [ "X${KERNEL_VER}" = "X4.19" ]; then
        RAMDISK_OPT="--ramdisk ${AOSP_ROOT}/out/target/product/hikey/ramdisk.img"
    else
        RAMDISK_OPT=""
    fi
    ${AOSP_ROOT}/out/host/linux-x86/bin/mkbootimg \
       --kernel ${ABS_KERNEL_OUT}/arch/arm64/boot/Image.gz-dtb \
       ${RAMDISK_OPT} \
       --cmdline "${KERNEL_CMDLINE}" \
       --os_version Q \
       --os_patch_level 2019-01-05 \
       --output ${AOSP_ROOT}/out/target/product/hikey//boot-${KERNEL_VER}-${KERNEL_DESCRIBE}.img
}


function build_android(){
    source build/envsetup.sh
    lunch hikey-userdebug
    TARGET_KERNEL_USE=4.19 make -j${CPUS} droidcore
    if false; then
        for image in "boot.img" "vendor.img" "system.img" "userdata.img"; do
            f_img=${AOSP_ROOT}/out/target/product/hikey/${image}
            if [ -f ${f_img} ]; then
                echo "Compressing ${f_img}"
                xz ${f_img}
            fi
        done
    fi
}

#build_android
# hack for edid test
#CMDLINE="${CMDLINE} drm_kms_helper.edid_firmware=edid/2048x1152.bin"
#build_hikey_bootimg 4.19 "${CMDLINE_4_19}"
build_hikey_bootimg 4.14 "${CMDLINE_4_14}"
