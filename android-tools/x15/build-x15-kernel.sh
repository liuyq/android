#!/bin/bash -x

CPUS=$(nproc)
ANDROID_ROOT=$(cd $(dirname $0); pwd)

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

function build_x15_kernel_pvr(){
    local KERNEL_VER=${1:-4.14} && shift

    #gcc_72_path="/data/android/aosp/master/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-7.2-linaro/"
    #export PATH=${gcc_72_path}/bin:$PATH
    TOOLCHAIN=4.9
    TOOLCHAIN=7.2-linaro

    KERNEL_SRC=${ANDROID_ROOT}/kernel/ti/x15-${KERNEL_VER}
    ABS_KERNEL_OUT=${ANDROID_ROOT}/out/target/product/beagle_x15/obj/x15-${KERNEL_VER}
    ARCH=arm
    KERNEL_CONFIG=ti_sdk_am57x_android_release_defconfig
    KERNEL_CROSS_COMPILE=${ANDROID_ROOT}/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-${TOOLCHAIN}/bin/arm-linux-androideabi-
    KERNEL_MAKE_TARGETS="zImage dtbs modules"
    CLANG_OPT=""

    cd ${KERNEL_SRC}
    git revert --no-edit 65d9e9821b86155dc810ff08c12cc29c7fabbca9
    cd -

    build_kernel "${KERNEL_SRC}" \
                    "${ABS_KERNEL_OUT}" \
                    "${ARCH}" \
                    "${KERNEL_CONFIG}" \
                    "${KERNEL_CROSS_COMPILE}" \
                    "${KERNEL_MAKE_TARGETS}" \
                    "${CLANG_OPT}"


    cp -vf ${ABS_KERNEL_OUT}/arch/arm/boot/zImage \
        ${ANDROID_ROOT}/device/ti/beagle_x15-kernel/4.14/zImage
    cp -vf ${ABS_KERNEL_OUT}/arch/arm/boot/dts/ti/am57xx-evm-common.dtbo \
        ${ANDROID_ROOT}/device/ti/beagle_x15-kernel/4.14/am57xx-evm-common.dtbo
    cp -vf ${ABS_KERNEL_OUT}/arch/arm/boot/dts/ti/am57xx-evm-reva3.dtbo \
        ${ANDROID_ROOT}/device/ti/beagle_x15-kernel/4.14/am57xx-evm-reva3.dtbo
    cp -vf ${ABS_KERNEL_OUT}/arch/arm/boot/dts/ti/am57xx-beagle-x15-revc.dtb \
        ${ANDROID_ROOT}/device/ti/beagle_x15-kernel/4.14/am57xx-beagle-x15-revc.dtb

    KERNEL_PVR_DIR=${KERNEL_SRC}/modules/eurasia_km/eurasiacon/build/linux2/omap_android
    # defined OUT according to info from modules/eurasia_km/eurasiacon/build/linux2/config/core.mk
    # PVR_MODULE_OUT=${X15_KERNEL_DIR}/modules/eurasia_km/eurasiacon/binary2_omap_android_release
    PVR_MODULE_OUT=${ANDROID_ROOT}/out/target/product/beagle_x15/obj/pvrsrvkm
    PVRSRVKM_KO_PATH=${PVR_MODULE_OUT}/target_armv7-a/pvrsrvkm.ko

    PVR_CROSS_COMPILE=${ANDROID_ROOT}/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
    make -j${CPUS} \
             -C ${KERNEL_PVR_DIR} \
             JAVAC=/bin/true \
             ARCH=arm \
             TARGET_DEVICE=am57xevm \
             CROSS_COMPILE=${PVR_CROSS_COMPILE} \
             KERNEL_CROSS_COMPILE=${PVR_CROSS_COMPILE} \
             EXCLUDED_APIS="composerhal,camerahal,unittests,sensorhal" \
             BUILD_PROP=${KERNEL_SRC}/modules/eurasia_km/build.prop \
             OUT=${PVR_MODULE_OUT} \
             KERNELDIR=${ABS_KERNEL_OUT}

    cp -v ${PVRSRVKM_KO_PATH} device/ti/beagle_x15-kernel/4.14/pvrsrvkm.ko
}

function build_android(){
    source build/envsetup.sh
    lunch beagle_x15-userdebug
    make -j${CPUS} droidcore bootfitimage
}

build_x15_kernel_pvr 4.14
build_android