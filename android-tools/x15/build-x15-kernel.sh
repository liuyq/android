#!/bin/bash -ex

gcc_72_path="/data/android/aosp/master/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-7.2-linaro/"
export PATH=${gcc_72_path}/bin:$PATH

#export CROSS_COMPILE=arm-eabi-
export CROSS_COMPILE=arm-linux-androideabi-
export ARCH=arm
cd kernel/ti/x15/ \
    && make mrproper \
    && make ti_sdk_am57x_android_release_defconfig \
    && make -j$(nproc) zImage dtbs modules \
    && cd -
cp -vf kernel/ti/x15/arch/arm/boot/dts/ti/am57xx-beagle-x15-revc.dtb device/ti/beagle_x15-kernel/4.14/am57xx-beagle-x15-revc.dtb
cp -vf kernel/ti/x15/arch/arm/boot/zImage device/ti/beagle_x15-kernel/4.14/zImage
cp -vf kernel/ti/x15/arch/arm/boot/dts/ti/am57xx-evm-common.dtbo device/ti/beagle_x15-kernel/4.14/am57xx-evm-common.dtbo
cp -vf kernel/ti/x15/arch/arm/boot/dts/ti/am57xx-evm-reva3.dtbo device/ti/beagle_x15-kernel/4.14/am57xx-evm-reva3.dtbo

source build/envsetup.sh
lunch beagle_x15-userdebug
make -j$(nproc)
