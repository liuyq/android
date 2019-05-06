#!/bin/bash -x

CLANG_VER=clang-r349610
AOSP_ROOT=/data/android/aosp/pie

if [ ! -d aarch64-gcc-4.9 ]; then
    git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 aarch64-gcc-4.9
fi
if [ ! -d clang-linux-x86 ]; then
    git clone --depth=1 https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 clang-linux-x86
fi
#export PATH=${PWD}/aarch64-linux-android-4.9/bin/:${PWD}/linux-x86/${TOOLCHAIN}/bin/:${PATH}
CLANG_ROOT=${PWD}/clang-linux-x86
GCC_49_ROOT=${PWD}/aarch64-gcc-4.9


SRC=${AOSP_ROOT}/kernel/ti/4.19/
OUT=${AOSP_ROOT}/out/target/product/am65xevm/obj/kernel-4.19-4.9
rm -fr ${OUT}
mkdir -p ${OUT}

cd ${SRC}
make mrproper
./ti_config_fragments/defconfig_builder.sh -t ti_sdk_arm64_android_release
make ARCH=arm64 ti_sdk_arm64_android_release_defconfig
mv -v ${SRC}/.config ${OUT}
make mrproper
cd -


make -j40 \
    -C ${SRC} \
    O=${OUT} \
    ARCH=arm64 \
    CROSS_COMPILE=${GCC_49_ROOT}/bin/aarch64-linux-androidkernel- \
    CLANG_TRIPLE=aarch64-linux-gnu-  \
    CC=${CLANG_ROOT}/${CLANG_VER}/bin/clang \
    HOSTCC=${CLANG_ROOT}/${CLANG_VER}/bin/clang \
    Image dtbs modules
