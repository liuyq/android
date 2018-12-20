#!/bin/bash -ex

KERNEL_VERBOSE="V=2 KBUILD_VERBOSE=1"
KERNEL_TARGET="Image-dtb"
KERNEL_TARGET="Image.gz-dtb"
CPUS=$(grep processor /proc/cpuinfo |wc -l)

MAKE="make"
HOST_PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

AOSP_ROOT=$(cd $(dirname $0)/..; pwd)

function build_kernel(){
    local KERNEL_SRC=$1 && shift
    local KERNEL_OUT=$1 && shift
    local CONFIG_FRAGMENTS_PATH=$1 && shift
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
#        echo "Failed to find the CLANG defined: ${CLANG_PREBUILT_BIN}"
#        exit 1
        clang_default_ver=$(grep -rn "ClangDefaultVersion.*=" build/soong/cc/config/global.go|cut -d= -f2|tr -d '" ')
        CLANG_PREBUILT_BIN=prebuilts/clang/host/linux-x86/${clang_default_ver}/bin/
    fi

    KERNEL_TOOLS_PREFIX=${AOSP_ROOT}/${LINUX_GCC_CROSS_COMPILE_PREBUILTS_BIN}/${CROSS_COMPILE}

    PATH=$PATH:${CLANG_PREBUILT_BIN}:${LINUX_GCC_CROSS_COMPILE_PREBUILTS_BIN}
    #CMD_MKCONFIG="${MAKE} -j1 -C ${KERNEL_SRC} -j1 ${KERNEL_VERBOSE} O=${KERNEL_OUT} ARCH=${ARCH} CROSS_COMPILE=${KERNEL_TOOLS_PREFIX} ${DEFCONFIG}"
    #PATH=$PATH:${HOST_PATH} ${CMD_MKCONFIG} 2>&1 | tee ${KERNEL_OUT}/build-mkconfig.log

    ################################# MAKE CONFIG #########
    possible_configs="android-base.config \
                      android-base-arm.config \
                      android-base-arm64.config \
                      android-recommended.config \
                      android-recommended-arm.config \
                      android-recommended-arm64.config \
                      android-base.cfg \
                      android-base-arm.cfg \
                      android-base-arm64.cfg \
                      android-recommended.cfg \
                      android-recommended-arm.cfg \
                      android-recommended-arm64.cfg \
                      "

    config_str='arch/arm64/configs/hikey_defconfig'
    configs_dir="${AOSP_ROOT}/kernel/configs"
    for config in ${possible_configs}; do
        if [ -f ${configs_dir}/${CONFIG_FRAGMENTS_PATH}/${config} ]; then
            config_str="${config_str} ${configs_dir}/${CONFIG_FRAGMENTS_PATH}/${config}"
        fi
    done

    # set value for KERNEL_MAKE_CONFIG_CMDS
    cd ${KERNEL_SRC} && KCONFIG_CONFIG=${KERNEL_OUT}/.merged.config ./scripts/kconfig/merge_config.sh -m ${config_str} && cd -
    make -j1 ${KERNEL_VERBOSE} \
        -C ${KERNEL_SRC} O=${KERNEL_OUT} \
        ARCH=${ARCH} CROSS_COMPILE="${KERNEL_TOOLS_PREFIX}" \
        KCONFIG_ALLCONFIG=${KERNEL_OUT}/.merged.config alldefconfig

    ################################# MAKE KERNEL #########
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

######################################################################
######################################################################
## build/make/core/version_defaults.mk
PLATFORM_SECURITY_PATCH="2017-12-01"
PLATFORM_VERSION=Q
#PLATFORM_VERSION=QPR1


#F_KERNEL="${AOSP_ROOT}/out/target/product/hikey/kernel"
F_RAMDISK="${AOSP_ROOT}/out/target/product/hikey/ramdisk.img"
BIN_MKBOOTIMG="${AOSP_ROOT}/out/host/linux-x86/bin/mkbootimg"
TARGET_BUILD_VARIANT="userdebug"
VERITY_KEYID=""
function make_bootimg(){
    local F_KERNEL=$1 && shift
    local F_RAMDISK=$1 && shift
    local F_BOOTIMG=$1 && shift
    local android_version=$1 && shift

    if echo "${android_version}" | grep -q 'o-'; then
        BOARD_KERNEL_CMDLINE="console=ttyAMA3,115200 androidboot.console=ttyAMA3 androidboot.hardware=hikey firmware_class.path=/system/etc/firmware efi=noruntime  printk.devkmsg=on"
    else
        BOARD_KERNEL_CMDLINE="console=ttyAMA3,115200 androidboot.console=ttyAMA3 androidboot.hardware=hikey firmware_class.path=/vendor/firmware efi=noruntime  printk.devkmsg=on overlay_mgr.overlay_dt_entry=hardware_cfg_enable_android_fstab"
    fi

    local INTERNAL_KERNEL_CMDLINE="${BOARD_KERNEL_CMDLINE} buildvariant=${TARGET_BUILD_VARIANT} ${VERITY_KEYID}"
    local INTERNAL_MKBOOTIMG_VERSION_ARGS="--os_version ${PLATFORM_VERSION} --os_patch_level ${PLATFORM_SECURITY_PATCH}"
    local BOARD_MKBOOTIMG_ARGS=""
    ${BIN_MKBOOTIMG}  --kernel ${F_KERNEL} --ramdisk ${F_RAMDISK} --cmdline "${INTERNAL_KERNEL_CMDLINE}" ${INTERNAL_MKBOOTIMG_VERSION_ARGS} ${BOARD_MKBOOTIMG_ARGS}  --output ${F_BOOTIMG}
}

KERNEL_SRC_BASE="${AOSP_ROOT}/kernel/linaro"
KERNEL_OUT_BASE="${AOSP_ROOT}/out/target/product/hikey/obj"

function build_single_version(){
    local kernel_ver=$1 && shift
    local android_version=$1 && shift
    local config_path=${android_version}/android-${kernel_ver}
    rm -fr ${KERNEL_OUT_BASE}/kernel-${kernel_ver}/arch/arm64/boot/${KERNEL_TARGET}
    rm -fr ${AOSP_ROOT}/out/target/product/hikey/boot-${kernel_ver}.img
    build_kernel "${KERNEL_SRC_BASE}/hisilicon-${kernel_ver}" ${KERNEL_OUT_BASE}/kernel-${kernel_ver} ${config_path}
    make_bootimg ${KERNEL_OUT_BASE}/kernel-${kernel_ver}/arch/arm64/boot/${KERNEL_TARGET} \
                    ${F_RAMDISK} \
                    ${AOSP_ROOT}/out/target/product/hikey/boot-${kernel_ver}.img \
                    ${android_version}
}

#build_single_version 4.19 .
#build_single_version 4.14 .
#build_single_version 4.9 .
#build_single_version 4.4 .

# need to repo sync the master kernel/configs
#build_single_version 4.14 p
#build_single_version 4.9 p
build_single_version 4.4 p

# need to repo sync the master kernel/configs
# and the master prebuilts/clang/host/linux-x86
#build_single_version 4.14 .
#build_single_version 4.9 o-mr1
#build_single_version 4.4 o-mr1
