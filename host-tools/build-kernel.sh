#!/bin/bash -ex

KERNEL_VERBOSE="V=1"
KERNEL_TARGET="Image-dtb"
KERNEL_TARGET="Image.gz-dtb"
CPUS=$(grep processor /proc/cpuinfo |wc -l)


MAKE="make"
HOST_PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

AOSP_ROOT=$(cd $(dirname $0)/..; pwd)
function build_kernel(){
    KERNEL_SRC=$1 && shift
    KERNEL_OUT=$1 && shift
    mkdir -p ${KERNEL_OUT}

    ## ARCH
    ## LINUX_GCC_CROSS_COMPILE_PREBUILTS_BIN
    ## CROSS_COMPILE
    ## DEFCONFIG
    ## CC && CLANG_PREBUILT_BIN for clang
    ## ClangDefaultVersion in build/soong/cc/config/global.go
    build_config=${KERNEL_SRC}/build.config.clang && use_clang=true
    source ${build_config}
    ## prebuilts-master/clang/host/linux-x86/clang-4679922/bin/
    CLANG_PREBUILT_BIN=$(echo ${CLANG_PREBUILT_BIN}|sed 's/-master//')
    if [ ! -d ${CLANG_PREBUILT_BIN} ]; then
        clang_default_ver=$(grep -rn "ClangDefaultVersion.*=" build/soong/cc/config/global.go|cut -d= -f2|tr -d '" ')
        CLANG_PREBUILT_BIN=prebuilts/clang/host/linux-x86/${clang_default_ver}/bin/
    fi

    KERNEL_TOOLS_PREFIX=${AOSP_ROOT}/${LINUX_GCC_CROSS_COMPILE_PREBUILTS_BIN}/${CROSS_COMPILE}

    PATH=$PATH:${CLANG_PREBUILT_BIN}:${LINUX_GCC_CROSS_COMPILE_PREBUILTS_BIN}
    CMD_MKCONFIG="${MAKE} -j1 -C ${KERNEL_SRC} -j1 ${KERNEL_VERBOSE} O=${KERNEL_OUT} ARCH=${ARCH} CROSS_COMPILE=${KERNEL_TOOLS_PREFIX} ${DEFCONFIG}"
    PATH=$PATH:${HOST_PATH} ${CMD_MKCONFIG} 2>&1 | tee ${KERNEL_OUT}/build-mkconfig.log 


    TOOLCHAIN_OPT="CROSS_COMPILE=${KERNEL_TOOLS_PREFIX}"
    if ${use_clang}; then
        ABS_CLANG=${AOSP_ROOT}/${CLANG_PREBUILT_BIN}/${CC}
        CLANG_OPT="CC=${ABS_CLANG} HOSTCC=${ABS_CLANG}"
        if [ -n "${CLANG_TRIPLE}" ]; then
            CLANG_TRIPLE_OPT="CLANG_TRIPLE=${CLANG_TRIPLE}"
        else
            CLANG_TRIPLE_OPT=""
        fi
        CLANG_OPT="${CLANG_OPT} ${CLANG_TRIPLE_OPT}"
        TOOLCHAIN_OPT="${TOOLCHAIN_OPT} ${CLANG_OPT}"
    else
        CLANG_OPT=""
    fi

    KERNEL_MAKE_CMDS="${MAKE} -j${CPUS} ${KERNEL_VERBOSE} -C ${KERNEL_SRC} O=${KERNEL_OUT} ARCH=${ARCH} ${TOOLCHAIN_OPT} ${KERNEL_TARGET}"
    PATH=$PATH:${HOST_PATH} ${KERNEL_MAKE_CMDS} 2>&1 | tee ${KERNEL_OUT}/build-kernel.log
}


function merge_kernel_config(){
    export ARCH=arm64
    export KERNEL_OUT=/development/android/master/out/target/product/hikey/obj/kernel
    export KERNEL_SRC=/development/android/master/kernel/linaro/hisilicon
    export KERNEL_CONFIG="\
        arch/arm64/configs/hikey_defconfig \
        configs/android-4.9/android-base.cfg \
        configs/android-4.9/android-base-arm64.cfg \
        configs/android-4.9/android-recommended.cfg \
        "
    export KCONFIG_CONFIG=${KERNEL_OUT}/.merged.config
    #cd ${KERNEL_SRC} && ./scripts/kconfig/merge_config.sh -m $(KERNEL_CONFIG) && cd - && make -j1 -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(ARCH) KCONFIG_ALLCONFIG=$(KERNEL_OUT)/.merged.config alldefconfig
    pushd ${KERNEL_SRC}
    ./scripts/kconfig/merge_config.sh -m ${KERNEL_CONFIG}
    popd
    make -j1 -C ${KERNEL_SRC} O=${KERNEL_OUT} ARCH=${ARCH} KCONFIG_ALLCONFIG=${KERNEL_OUT}/.merged.config alldefconfig
}
######################################################################
######################################################################
## build/make/core/version_defaults.mk
PLATFORM_SECURITY_PATCH="2017-12-01"
PLATFORM_VERSION=Q
#PLATFORM_VERSION=QPR1


F_KERNEL="${AOSP_ROOT}/out/target/product/hikey/kernel"
F_RAMDISK="${AOSP_ROOT}/out/target/product/hikey/ramdisk.img"
BIN_MKBOOTIMG="${AOSP_ROOT}/out/host/linux-x86/bin/mkbootimg"
BOARD_KERNEL_CMDLINE="console=ttyFIQ0 androidboot.console=ttyFIQ0 androidboot.hardware=hikey firmware_class.path=/vendor/firmware efi=noruntime overlay_mgr.overlay_dt_entry=hardware_cfg_enable_android_fstab video=HDMI-A-1:1280x720@60 printk.devkmsg=on"
TARGET_BUILD_VARIANT="userdebug"
VERITY_KEYID=""
function make_bootimg(){
    local F_KERNEL=$1 && shift
    local F_RAMDISK=$1 && shift
    local F_BOOTIMG=$1 && shift

    local INTERNAL_KERNEL_CMDLINE="${BOARD_KERNEL_CMDLINE} buildvariant=${TARGET_BUILD_VARIANT} ${VERITY_KEYID}"
    local INTERNAL_MKBOOTIMG_VERSION_ARGS="--os_version ${PLATFORM_VERSION} --os_patch_level ${PLATFORM_SECURITY_PATCH}"
    local BOARD_MKBOOTIMG_ARGS=""
    ${BIN_MKBOOTIMG}  --kernel ${F_KERNEL} --ramdisk ${F_RAMDISK} --cmdline "${INTERNAL_KERNEL_CMDLINE}" ${INTERNAL_MKBOOTIMG_VERSION_ARGS} ${BOARD_MKBOOTIMG_ARGS}  --output ${F_BOOTIMG}
}

KERNEL_SRC_BASE="${AOSP_ROOT}/kernel/linaro"
KERNEL_OUT_BASE="${AOSP_ROOT}/out/target/product/hikey/obj"

function build_single_version(){
    local ver=$1 && shift
    rm -fr ${KERNEL_OUT_BASE}/kernel-${ver}/arch/arm64/boot/Image.gz-dtb
    rm -fr ${AOSP_ROOT}/out/target/product/hikey/boot-${ver}.img
    build_kernel "${KERNEL_SRC_BASE}/hisilicon-${ver}" ${KERNEL_OUT_BASE}/kernel-${ver}
    make_bootimg ${KERNEL_OUT_BASE}/kernel-${ver}/arch/arm64/boot/Image.gz-dtb ${F_RAMDISK} ${AOSP_ROOT}/out/target/product/hikey/boot-${ver}.img
}

build_single_version 4.14
build_single_version 4.9
build_single_version 4.4
