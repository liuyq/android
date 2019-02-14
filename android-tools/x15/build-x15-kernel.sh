#!/bin/bash -ex

ANDROID_ROOT=$(cd $(dirname $0); pwd)
KERNEL_SRC=${ANDROID_ROOT}/kernel/ti/x15
KERNEL_OUT=${ANDROID_ROOT}/out/target/product/beagle_x15/obj/kernel-4.14

if true; then
    #gcc_72_path="/data/android/aosp/master/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-7.2-linaro/"
    #export PATH=${gcc_72_path}/bin:$PATH
    TOOLCHAIN=4.9
    TOOLCHAIN=7.2-linaro

    export X15_KERNEL_DIR=${KERNEL_SRC}
    CROSS_COMPILE=${ANDROID_ROOT}/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-${TOOLCHAIN}/bin/arm-linux-androideabi-
    cd kernel/ti/x15/ \
        && make mrproper \
        && make ARCH=arm ti_sdk_am57x_android_release_defconfig \
        && make -j$(nproc) \
                ARCH=arm \
                CROSS_COMPILE=${CROSS_COMPILE} \
                zImage dtbs modules \
        && cd -
    cp -vf kernel/ti/x15/arch/arm/boot/dts/ti/am57xx-beagle-x15-revc.dtb device/ti/beagle_x15-kernel/4.14/am57xx-beagle-x15-revc.dtb
    cp -vf kernel/ti/x15/arch/arm/boot/zImage device/ti/beagle_x15-kernel/4.14/zImage
    cp -vf kernel/ti/x15/arch/arm/boot/dts/ti/am57xx-evm-common.dtbo device/ti/beagle_x15-kernel/4.14/am57xx-evm-common.dtbo
    cp -vf kernel/ti/x15/arch/arm/boot/dts/ti/am57xx-evm-reva3.dtbo device/ti/beagle_x15-kernel/4.14/am57xx-evm-reva3.dtbo

    KERNEL_PVR_DIR=${X15_KERNEL_DIR}/modules/eurasia_km/eurasiacon/build/linux2/omap_android
    PVR_CROSS_COMPILE=${ANDROID_ROOT}/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
    cd ${KERNEL_PVR_DIR} && \
        make -j$(nproc) \
             JAVAC=/bin/true \
             ARCH=arm \
             TARGET_DEVICE=am57xevm \
             CROSS_COMPILE=${PVR_CROSS_COMPILE} \
             KERNEL_CROSS_COMPILE=${PVR_CROSS_COMPILE} \
             EXCLUDED_APIS="composerhal,camerahal,unittests,sensorhal" \
             BUILD_PROP=${X15_KERNEL_DIR}/modules/eurasia_km/build.prop \
             KERNELDIR=${X15_KERNEL_DIR} && \
        cd -
    PVRSRVKM_KO_PATH=modules/eurasia_km/eurasiacon/binary2_omap_android_release/target_armv7-a/pvrsrvkm.ko
    cp ${X15_KERNEL_DIR}/${PVRSRVKM_KO_PATH} device/ti/beagle_x15-kernel/4.14/pvrsrvkm.ko

fi

if true; then
    source build/envsetup.sh
    lunch beagle_x15-userdebug
    make -j$(nproc) droidcore bootfitimage
fi
