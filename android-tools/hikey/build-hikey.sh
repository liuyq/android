#!/bin/bash -ex

AOSP_ROOT=$(cd $(dirname $0); pwd)

CPUS=$(nproc)
export TARGET_KERNEL_USE=4.19

if true; then
    source build/envsetup.sh
    lunch hikey-userdebug
    make -j${CPUS} droidcore
fi
#cd out/target/product/hikey/
#for image in "boot.img" "vendor.img" "boot_fat.uefi.img" "system.img" "userdata.img"  "cache.img"; do
#  if [ -f ${image} ]; then
#    echo "Compressing ${image}"
#    xz ${image}
#  fi
#done
#cd -

TOOLCHAIN=clang-r346389c
export PATH=${AOSP_ROOT}/prebuilts/clang/host/linux-x86/${TOOLCHAIN}/bin/:${AOSP_ROOT}/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/:${PATH}

export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-android-
CMDLINE="console=ttyAMA3,115200 androidboot.console=ttyAMA3"
CMDLINE="${CMDLINE} androidboot.hardware=hikey firmware_class.path=/vendor/firmware efi=noruntime"
CMDLINE="${CMDLINE} init=/init androidboot.boot_devices=soc/f723d000.dwmmc0"
CMDLINE="${CMDLINE} printk.devkmsg=on buildvariant=userdebug"

if true; then
    cd ${AOSP_ROOT}/kernel/linaro/hisilicon-4.19/
    export KERNEL_DESCRIBE_4_19=$(git rev-parse --short HEAD)
    ARCH=arm64 scripts/kconfig/merge_config.sh arch/arm64/configs/hikey_defconfig ${AOSP_ROOT}/kernel/configs/android-4.19/android-base.config
    make ARCH=arm64 CC=clang HOSTCC=clang -j$(nproc) -s Image.gz-dtb
    ${AOSP_ROOT}/out/host/linux-x86/bin/mkbootimg \
       --kernel arch/arm64/boot/Image.gz-dtb \
       --ramdisk ${AOSP_ROOT}/out/target/product/hikey/ramdisk.img \
       --cmdline "${CMDLINE}" \
       --os_version Q \
       --os_patch_level 2019-01-05 \
       --output ${AOSP_ROOT}/out/target/product/hikey//boot-4.19-${KERNEL_DESCRIBE_4_19}.img
    rm -fr ${AOSP_ROOT}/out/target/product/hikey/4.19_vmlinux && cp vmlinux ${AOSP_ROOT}/out/target/product/hikey/4.19_vmlinux
    rm -fr ${AOSP_ROOT}/out/target/product/hikey/4.19_defconfig && cp .config ${AOSP_ROOT}/out/target/product/hikey/4.19_defconfig
    #xz ${AOSP_ROOT}/out/target/product/hikey/boot-4.19-${KERNEL_DESCRIBE_4_19}.img
fi

# common for 4.9 and 4.14
# set verity and system-as-root kernel boot parameters for 4.14 and 4.9
CMDLINE="${CMDLINE} overlay_mgr.overlay_dt_entry=hardware_cfg_enable_android_fstab_v2"
CMDLINE="${CMDLINE} rootwait ro root=/dev/dm-0"
CMDLINE="${CMDLINE} dm=\"system none ro,0 1 android-verity 179:9\""
CMDLINE="${CMDLINE} veritykeyid=id:7e4333f9bba00adfe0ede979e28ed1920492b40f"

# Build 4.14 kernel
cd ${AOSP_ROOT}/kernel/linaro/hisilicon-4.14/
export KERNEL_DESCRIBE_4_14=$(git rev-parse --short HEAD)
ARCH=arm64 scripts/kconfig/merge_config.sh arch/arm64/configs/hikey_defconfig ${AOSP_ROOT}/kernel/configs/android-4.14/android-base.config
make ARCH=arm64 CC=clang HOSTCC=clang -j$(nproc) -s Image.gz-dtb
${AOSP_ROOT}/out/host/linux-x86/bin/mkbootimg \
  --kernel arch/arm64/boot/Image.gz-dtb \
  --cmdline "${CMDLINE}" \
  --os_version Q \
  --os_patch_level 2019-01-05 \
  --output ${AOSP_ROOT}/out/target/product/hikey/boot-4.14-${KERNEL_DESCRIBE_4_14}.img
rm -fr ${AOSP_ROOT}/out/target/product/hikey/4.14_vmlinux && cp vmlinux ${AOSP_ROOT}/out/target/product/hikey/4.14_vmlinux
rm -fr ${AOSP_ROOT}/out/target/product/hikey/4.14_defconfig && cp .config ${AOSP_ROOT}/out/target/product/hikey/4.14_defconfig
#xz ${AOSP_ROOT}/out/target/product/hikey/boot-4.14-${KERNEL_DESCRIBE_4_14}.img
