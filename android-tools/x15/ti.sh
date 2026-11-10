#!/bin/bash -ex

######## functions define for am65x lkft builds ################
function ti_generate_kernel_config(){
    local builder_item=$1 && shift

    local OPTS_KERNEL_TOOLCHAIN=$(get_toolchain_opts_for_make_kernel)

    cd ${BUILD_KERNEL_SRC_DIR} && make ARCH=${BUILD_ARCH} mrproper
    ./ti_config_fragments/defconfig_builder.sh -t "${builder_item}"
    make -j1 ARCH=${BUILD_ARCH} ${OPTS_KERNEL_TOOLCHAIN} "${builder_item}_defconfig"
    mv -v .config ${DIR_ABS_KERNEL_OUT}/

    # remove the generate temporary file
    rm -f arch/${BUILD_ARCH}/configs/${builder_item}_defconfig
    make ARCH=${BUILD_ARCH} mrproper
    cd -
}

function am65x_generate_kernel_config(){
    local builder_item="ti_sdk_arm64_android_release"
    ti_generate_kernel_config ${builder_item}
}
function x15_generate_kernel_config(){
    local builder_item="ti_sdk_am57x_android_release"
    ti_generate_kernel_config ${builder_item}
}

function x15_mainline_generate_kernel_config(){
    cd ${BUILD_KERNEL_SRC_DIR}

    mkdir -p ${DIR_ABS_KERNEL_OUT}
    local f_merged_config=${DIR_ABS_KERNEL_OUT}/merged.config
    KCONFIG_CONFIG=${f_merged_config} ./scripts/kconfig/merge_config.sh -m \
        arch/arm/configs/multi_v7_defconfig \
        ti_config_fragments/multi_v7_prune.cfg \
        ti_config_fragments/baseport.cfg \
        ti_config_fragments/ipc.cfg \
        ti_config_fragments/connectivity.cfg \
        ti_config_fragments/audio_display.cfg \
        ti_config_fragments/omap_soc.cfg \
        ti_config_fragments/lpae.cfg \
        ti_config_fragments/dra7_only.cfg \
        ti_config_fragments/systemd.cfg \
        ${DIR_TOP}/kernel/configs/android-4.19/android-base.config \
        ${DIR_TOP}/kernel/configs/android-4.19/android-recommended.config \
        ti_config_fragments/android.cfg

    local OPTS_KERNEL_TOOLCHAIN=$(get_toolchain_opts_for_make_kernel)
    make ARCH=${BUILD_ARCH} ${OPTS_KERNEL_TOOLCHAIN} KCONFIG_ALLCONFIG=${f_merged_config} O=${DIR_ABS_KERNEL_OUT} alldefconfig
    cd -

}

function ti_create_boot_fit_img(){
    local its_url=$1 && shift
    local kernel_file_name=$1 && shift
    local DIR_FIT=${DIR_ABS_OUT}/fit

    local final_name=$(func_get_when_not_exist ramdisk.img)

    rm -fr ${DIR_FIT} && mkdir -p ${DIR_FIT}

    cp -vf ${DIR_ABS_OUT}/${final_name} ${DIR_FIT}/ramdisk.img

    local its_name=$(basename ${its_url}|cut -d\? -f1)
    local its_final_name=$(func_wget_with_f_ref_url_and_f_name "${its_url}" "${its_name}")
    cp -vf ${DIR_ABS_OUT}/${its_final_name} ${DIR_FIT}/${its_name}

    cp -vf ${DIR_ABS_KERNEL_OUT}/arch/${BUILD_ARCH}/boot/${kernel_file_name} ${DIR_FIT}
    if [ -n "$(find ${DIR_ABS_KERNEL_OUT}/arch/${BUILD_ARCH}/boot/dts/ti/ -name *.dtb)" ]; then
        cp -vf ${DIR_ABS_KERNEL_OUT}/arch/${BUILD_ARCH}/boot/dts/ti/*.dtb ${DIR_FIT}
    elif [ -n "$(find ${DIR_ABS_KERNEL_OUT}/arch/${BUILD_ARCH}/boot/dts/ -name *.dtb)" ]; then
        cp -vf ${DIR_ABS_KERNEL_OUT}/arch/${BUILD_ARCH}/boot/dts/*.dtb ${DIR_FIT}
    fi
    if [ -n "$(find ${DIR_ABS_KERNEL_OUT}/arch/${BUILD_ARCH}/boot/dts/ti/ -name *.dtbo)" ]; then
       cp -vf ${DIR_ABS_KERNEL_OUT}/arch/${BUILD_ARCH}/boot/dts/ti/*.dtbo ${DIR_FIT}
    fi

    # need to use dtc command
    PATH=${DIR_ABS_LINARO_HOST_BIN}/:${PATH} \
        ${DIR_ABS_LINARO_HOST_BIN}/mkimage -D "-I dts -O dtb -p 500 -Wno-unit_address_vs_reg" \
            -f ${DIR_FIT}/${its_name} \
            ${DIR_ABS_OUT}/boot_fit.img
}

function am65x_create_boot_fit_img(){
    local its_url="http://git.ti.com/android/device-ti-am65xevm/blobs/raw/d-pie-core-release/am65x-evm.its"
    local kernel_file_name="Image"

    ti_create_boot_fit_img "${its_url}" "${kernel_file_name}"
}

function x15_create_boot_fit_img(){
    local its_url="http://git.ti.com/android/device-ti-beagle-x15/blobs/raw/d-pie-core-release/beagle_x15.its"
    local kernel_file_name="zImage"
    ti_create_boot_fit_img "${its_url}" "${kernel_file_name}"
}

function x15_mainline_create_boot_fit_img(){
    local its_url="https://android-git.linaro.org/android-build-configs.git/plain/lkft/scripts/x15/beagle_x15-mainline.its?h=lkft"
    local kernel_file_name="zImage"
    ti_create_boot_fit_img "${its_url}" "${kernel_file_name}"
}

function ti_create_vendor_img(){
    local files_to_be_copied="$@"
    local final_name=$(func_get_when_not_exist vendor.img)

    local DIR_KERNEL_MODULES=${DIR_ABS_OUT}/module
    local DIR_VENDOR=${DIR_ABS_OUT}/vendor
    rm -fr ${DIR_KERNEL_MODULES} ${DIR_VENDOR}
    mkdir -p ${DIR_KERNEL_MODULES} ${DIR_VENDOR}

    number=$(find ${DIR_ABS_KERNEL_OUT} -name '*.ko'|wc -l)
    if [ ${number} -eq 0 ]; then
        echo "No kernel modules generated"
        echo "And no need to recreate the vendor.img again!"
        cp -vf ${DIR_ABS_OUT}/${final_name} ${DIR_ABS_OUT}/vendor.img
        return
    fi

    ${DIR_ABS_LINARO_HOST_BIN}/simg2img ${DIR_ABS_OUT}/${final_name} ${DIR_ABS_OUT}/vendor-raw.img
    sudo mount -o loop ${DIR_ABS_OUT}/vendor-raw.img ${DIR_VENDOR}

    # build/core/Makefile build-image-kernel-modules
    mkdir -p ${DIR_KERNEL_MODULES}/lib/modules/0.0/vendor/lib/modules
    if [ -e  ${DIR_VENDOR}/lib/modules ]; then
        cp -r ${DIR_VENDOR}/lib/modules/* ${DIR_KERNEL_MODULES}/lib/modules/0.0/vendor/lib/modules
    else
        sudo mkdir -p ${DIR_VENDOR}/lib/modules
        sudo setfilecon u:object_r:vendor_file:s0 ${DIR_VENDOR}/lib/modules
    fi

    need_to_set_filecon=false
    for f in `find ${DIR_ABS_KERNEL_OUT} -name '*.ko'|tr '\n' ' '`; do
        cp -f $f ${DIR_KERNEL_MODULES}/lib/modules/0.0/vendor/lib/modules
        ! ${need_to_set_filecon} && [ ! -f "${DIR_VENDOR}/lib/modules/$(basename $f)" ] && need_to_set_filecon=true
        sudo cp -f $f ${DIR_VENDOR}/lib/modules/
    done
    if ${need_to_set_filecon}; then
        sudo setfilecon u:object_r:vendor_file:s0 ${DIR_VENDOR}/lib/modules/*.ko
    fi

    ${DIR_ABS_LINARO_HOST_BIN}/depmod -b ${DIR_KERNEL_MODULES} 0.0
    sed -e 's/\(.*modules.*\):/\/\1:/g' -e 's/ \([^ ]*modules[^ ]*\)/ \/\1/g' ${DIR_KERNEL_MODULES}/lib/modules/0.0/modules.dep > ${DIR_KERNEL_MODULES}/modules.dep
    sudo cp ${DIR_KERNEL_MODULES}/modules.dep ${DIR_VENDOR}/lib/modules/modules.dep
    sudo cp ${DIR_KERNEL_MODULES}/lib/modules/0.0/modules.alias ${DIR_VENDOR}/lib/modules/modules.alias
    sudo setfilecon u:object_r:vendor_file:s0 ${DIR_VENDOR}/lib/modules/modules.dep
    sudo setfilecon u:object_r:vendor_file:s0 ${DIR_VENDOR}/lib/modules/modules.alias

    ## assuming the files are not ko files.
    for f in ${files_to_be_copied}; do
        f_src=$(echo $f|cut -d: -f1)
        f_dest=$(echo $f|cut -d: -f2)

        need_to_set_filecon=false && [ ! -f "${DIR_VENDOR}/${f_dest}" ] && need_to_set_filecon=true
        sudo cp -vf ${f_src} ${DIR_VENDOR}/${f_dest}
        if ${need_to_set_filecon}; then
            sudo setfilecon u:object_r:vendor_file:s0 ${DIR_VENDOR}/${f_dest}
        fi
    done

    sudo sync
    sudo umount ${DIR_VENDOR}
    ${DIR_ABS_LINARO_HOST_BIN}/img2simg ${DIR_ABS_OUT}/vendor-raw.img ${DIR_ABS_OUT}/vendor.img

    rm -f ${DIR_ABS_OUT}/vendor-raw.img
}

function x15_mainline_ti_create_vendor_img(){
    local f_fstab_v5_url="https://android-git.linaro.org/android-build-configs.git/plain/lkft/scripts/x15/fstab.beagle_x15board_v5?h=lkft"
    wget ${f_fstab_v5_url} -O ${DIR_ABS_OUT}/fstab.beagle_x15board_v5
    ti_create_vendor_img ${DIR_ABS_OUT}/fstab.beagle_x15board_v5:etc/fstab.beagle_x15board
}

function x15_u_boot_img(){
    local DIR_UBOOT_SRC=${DIR_TOP}/firmware/u-boot
    local DIR_UBOOT_OUT=${DIR_ABS_OUT}/firmware/u-boot

    make -j1 \
        ARCH=${BUILD_ARCH} \
        -C ${DIR_UBOOT_SRC} \
        O=${DIR_UBOOT_OUT} \
        CROSS_COMPILE=${DIR_TOP}/${BUILD_KERNEL_CCROSS_COMPILE} \
        am57xx_evm_defconfig

    make -j${CPUS} \
        ARCH=arm \
        -C ${DIR_UBOOT_SRC} \
        O=${DIR_UBOOT_OUT} \
        CROSS_COMPILE=${DIR_TOP}/${BUILD_KERNEL_CCROSS_COMPILE}

    rm -f ${DIR_ABS_OUT}/u-boot.img
    cp -vf ${DIR_UBOOT_OUT}/u-boot.img ${DIR_ABS_OUT}/u-boot.img
}

# needs the x15_u_boot_img to be run first
function x15_mlo(){
    local DIR_UBOOT_SRC=${DIR_TOP}/firmware/u-boot
    local DIR_UBOOT_OUT=${DIR_ABS_OUT}/firmware/u-boot

    rm -f ${DIR_ABS_OUT}/MLO
    cp -vf ${DIR_UBOOT_OUT}/MLO ${DIR_ABS_OUT}/MLO
}

function x15_create_boot_img_4_19(){
    local boot_devices="${1}"

    local boot_partition_size=20971520 #20 MiB
    local f_ramdisk_name="ramdisk.img"
    local orignal_ramdisk=$(func_get_when_not_exist "${f_ramdisk_name}")
    local new_ramdisk_name=${orignal_ramdisk}

    local dir_dist="${DIR_ABS_KERNEL_OUT}"
    local dir_zimage="${DIR_ABS_KERNEL_OUT}/arch/arm/boot/"
    if [ -n "${TUXSUITE_BAKE_VENDOR_DOWNLOAD_URL}" ]; then
        download_tuxsuite_prebuilts
        dir_dist="${DIR_ABS_KERNEL_OUT}"
        dir_zimage="${DIR_ABS_KERNEL_OUT}"
    elif [ -n "${BUILD_KERNEL_BAZEL_TARGET}" ]; then
        # Note1:
        #     tuxsuite kernel build will not be here
        #     it will go to the TUXSUITE_BAKE_VENDOR_DOWNLOAD_URL branch
        # Note2:
        #     BUILD_KERNEL_BAZEL_TARGET and BUILD_KERNEL_WITH_UPSTREAM_BUILD both are set,
        #     then it should go here
        dir_dist="${DIR_ABS_KERNEL_OUT}"
        dir_zimage="${DIR_ABS_KERNEL_OUT}"
    elif echo "${BUILD_KERNEL_WITH_UPSTREAM_BUILD}" |grep -i -q 'true'; then
        # find the generated ko files from the dist directory when build with build/build.sh
        # as some modules might be in the out of kernel tree directories, like the hikey/hikey960 mali modules
        dir_dist=${DIR_ABS_OUT}/vendor-kernel/dist
    fi

    local f_dtb_dist="${dir_dist}/am57xx-beagle-x15-revc.dtb"
    local f_dtb_5x="${DIR_ABS_KERNEL_OUT}/arch/arm/boot/dts/ti/am57xx-beagle-x15-revc.dtb"
    local f_dtb_4x="${DIR_ABS_KERNEL_OUT}/arch/arm/boot/dts/am57xx-beagle-x15-revc.dtb"
    local f_dtb="${f_dtb_4x}"
    if [ -f "${f_dtb_dist}" ]; then
        f_dtb="${f_dtb_dist}"
    elif [ -f "${f_dtb_5x}" ]; then
        f_dtb="${f_dtb_5x}"
    fi
    rm -f ${DIR_ABS_OUT}/dtb.img && cp -fv ${f_dtb} ${DIR_ABS_OUT}/dtb.img

    rm -f ${DIR_ABS_OUT}/boot.img ${DIR_ABS_OUT}/boot.img.xz
    if [ -n "${boot_devices}" ]; then
        para_boot_devices="androidboot.boot_devices=${boot_devices}"
    else
        para_boot_devices=""
    fi

    local f_kernel="${dir_zimage}/zImage"
    ${DIR_ABS_LINARO_HOST_BIN}/mkbootimg \
        --kernel ${f_kernel} \
        --ramdisk ${DIR_ABS_OUT}/${new_ramdisk_name} \
        --dtb ${DIR_ABS_OUT}/dtb.img \
        --cmdline "buildvariant=userdebug androidboot.verifiedbootstate=orange ${para_boot_devices}" \
        --os_version R \
        --os_patch_level 2020-04-05 \
        --header_version 2 \
        --output ${DIR_ABS_OUT}/boot.img

    ${DIR_ABS_LINARO_HOST_BIN}/avbtool add_hash_footer \
    --image ${DIR_ABS_OUT}/boot.img \
    --partition_size ${boot_partition_size} \
    --partition_name boot \
    --prop com.android.build.boot.fingerprint:$(get_build_fingerprint) \
    --prop com.android.build.boot.os_version:R

    rm -f ${DIR_ABS_OUT}/boot.img.xz
    xz -T0 -k ${DIR_ABS_OUT}/boot.img
}


function x15_dtbo_img_4_19(){
    local f_dtbo=${DIR_ABS_OUT}/dtbo.img
    local f_dtbo_unsigned=${DIR_ABS_OUT}/dtbo-unsigned.img

    local dtbo_partition_size="8388608" #8 MiB

    local dir_dtb="${DIR_ABS_KERNEL_OUT}/arch/arm/boot/dts/ti/"
    if [ -n "${TUXSUITE_BAKE_VENDOR_DOWNLOAD_URL}" ]; then
        download_tuxsuite_prebuilts
        dir_dtb="${DIR_ABS_KERNEL_OUT}"
    fi
    ${DIR_ABS_LIBUFDT}/mkdtimg  create \
        ${f_dtbo_unsigned} \
        ${dir_dtb}/am57xx-evm-common.dtbo \
        ${dir_dtb}/am57xx-evm-reva3.dtbo

    cp ${f_dtbo_unsigned} ${f_dtbo}
    ${DIR_ABS_LINARO_HOST_BIN}/avbtool add_hash_footer \
        --image ${f_dtbo} \
        --partition_size ${dtbo_partition_size} \
        --partition_name dtbo \
        --prop com.android.build.dtbo.fingerprint:$(get_build_fingerprint) \
        --prop com.android.build.boot.os_version:R

    rm -f ${f_dtbo_unsigned}

    rm -f ${f_dtbo}.xz
    xz -T0 -k ${f_dtbo}
}

function get_build_fingerprint(){
    # ro.system.build.fingerprint=Android/beagle_x15/beagle_x15:R/AOSP.MASTER/liuyq04131326:userdebug/test-keys
    # same as the one in out/target/product/beagle_x15/build_fingerprint.txt

    # export does not work here
    if [ -n "${X15_BUILD_FINGERPRINT}" ]; then
        echo "${X15_BUILD_FINGERPRINT}"
        return
    fi
    get_build_fingerprint_from_system_img

    #local f_build_prop=$(func_get_when_not_exist build.prop)
    #local build_fingerprint=$(grep 'ro.system.build.fingerprint=' ${DIR_ABS_OUT}/${f_build_prop}|cut -d= -f 2)
    #echo "${build_fingerprint}"
}

function get_build_fingerprint_from_system_img(){
    local f_system=$(func_get_when_not_exist "system.img.xz")
    rm -f ${DIR_ABS_OUT}/system.img && \
        cp ${DIR_ABS_OUT}/${f_system} ${DIR_ABS_OUT}/system.img.xz && \
        xz -T 0 -d ${DIR_ABS_OUT}/system.img.xz

    local DIR_SYSTEM=${DIR_ABS_OUT}/system
    mkdir -p ${DIR_SYSTEM}
    ${DIR_ABS_LINARO_HOST_BIN}/simg2img ${DIR_ABS_OUT}/system.img ${DIR_ABS_OUT}/system-raw.img
    sudo mount -o loop ${DIR_ABS_OUT}/system-raw.img ${DIR_SYSTEM}
    local build_fingerprint=$(sudo grep -s 'ro.system.build.fingerprint=' ${DIR_SYSTEM}/system/build.prop|cut -d= -f 2)
    sleep 1
    sudo umount ${DIR_SYSTEM}
    rm -f ${DIR_ABS_OUT}/system.img.xz ${DIR_ABS_OUT}/system.img ${DIR_ABS_OUT}/system-raw.img
    rmdir ${DIR_SYSTEM}


    # export does not work here
    export X15_BUILD_FINGERPRINT=${build_fingerprint}
    echo "${build_fingerprint}"
}

function x15_create_vbmeta_img(){
    local has_dtbo="${1}"
    local url_testkey="https://android-git.linaro.org/platform/external/avb.git/plain/test/data/testkey_rsa4096.pem"
    local f_testkey_rsa4096_pem=$(func_wget_with_f_ref_url_and_f_name "${url_testkey}" "testkey_rsa4096.pem")

    local f_recovery=$(func_get_when_not_exist "recovery.img.xz")
    local f_system=$(func_get_when_not_exist "system.img.xz")
    local f_vendor=$(func_get_when_not_exist "vendor.img.xz")

    rm -f ${DIR_ABS_OUT}/recovery.img && \
        cp -v ${DIR_ABS_OUT}/${f_recovery} ${DIR_ABS_OUT}/recovery.img.xz && \
        xz -T 0 -d ${DIR_ABS_OUT}/recovery.img.xz

    rm -f ${DIR_ABS_OUT}/system.img && \
        cp -v ${DIR_ABS_OUT}/${f_system} ${DIR_ABS_OUT}/system.img.xz && \
        xz -T 0 -d ${DIR_ABS_OUT}/system.img.xz

    rm -f ${DIR_ABS_OUT}/vendor.img && \
        cp -v ${DIR_ABS_OUT}/${f_vendor} ${DIR_ABS_OUT}/vendor.img.xz && \
        xz -T 0 -d ${DIR_ABS_OUT}/vendor.img.xz

    opt_dtbo="--include_descriptors_from_image ${DIR_ABS_OUT}/dtbo.img"
    if [ -n "${has_dtbo}" ] && ! ${has_dtbo}; then
        opt_dtbo=""
    fi
    ${DIR_ABS_LINARO_HOST_BIN}/avbtool make_vbmeta_image \
        --include_descriptors_from_image ${DIR_ABS_OUT}/boot.img \
        --include_descriptors_from_image ${DIR_ABS_OUT}/system.img \
        --include_descriptors_from_image ${DIR_ABS_OUT}/vendor.img \
        ${opt_dtbo} \
        --include_descriptors_from_image ${DIR_ABS_OUT}/recovery.img \
        --algorithm SHA256_RSA4096 \
        --key ${DIR_ABS_OUT}/${f_testkey_rsa4096_pem} \
        --padding_size 4096 \
        --output ${DIR_ABS_OUT}/vbmeta.img

    rm -f ${DIR_ABS_OUT}/boot.img ${DIR_ABS_OUT}/system.img ${DIR_ABS_OUT}/vendor.img ${DIR_ABS_OUT}/dtbo.img ${DIR_ABS_OUT}/recovery.img

    rm -fr ${DIR_ABS_OUT}/vbmeta.img.xz
    xz -T0 ${DIR_ABS_OUT}/vbmeta.img
    #rm -rf ${DIR_ABS_OUT}/avb_chain_keys
}

function x15_create_super_img(){
    local f_fstab_name="${1}"
    local f_system=$(func_get_when_not_exist "system.img.xz")
    local f_vendor=$(func_get_when_not_exist "vendor.img.xz")
    local build_fingerprint=$(get_build_fingerprint)

    rm -f ${DIR_ABS_OUT}/system.img && \
        cp -v ${DIR_ABS_OUT}/${f_system} ${DIR_ABS_OUT}/system.img.xz && \
        xz -T 0 -d ${DIR_ABS_OUT}/system.img.xz

    rm -f ${DIR_ABS_OUT}/vendor.img && \
        cp -v ${DIR_ABS_OUT}/${f_vendor} ${DIR_ABS_OUT}/vendor.img.xz && \
        xz -T 0 -d ${DIR_ABS_OUT}/vendor.img.xz

    local super_partition_size=2684354560 #2560M
    local super_partition_group_name=group_oem
    local super_partition_group_list="system vendor"
    local super_partition_group_size=1341652992 #1279.5 MiB

    local para_files=""
    if [ -n "${f_fstab_name}" ]; then
        local f_fstab_v5_url="https://android-git.linaro.org/android-build-configs.git/plain/lkft/scripts/x15/${f_fstab_name}?h=lkft"
        local fstab_final_name=$(func_wget_with_f_ref_url_and_f_name "${f_fstab_v5_url}" "${f_fstab_name}")
        #para_files="${DIR_ABS_OUT}/${fstab_final_name}:etc/fstab.beagle_x15board"
        para_files="${DIR_ABS_OUT}/${fstab_final_name}|etc/fstab.beagle_x15board|0:0|0755|u:object_r:vendor_configs_file:s0"
    fi
    recreate_vendor_img "${DIR_ABS_OUT}/vendor.img" false true 280 "${para_files}"
    vendor_partition_size=314572800 #300MB

# for auto build
#    recreate_vendor_img "${DIR_ABS_OUT}/vendor.img" false true 120 "${para_files}"
#    vendor_partition_size=134217728 #128MB
    ${DIR_ABS_LINARO_HOST_BIN}/avbtool add_hash_footer \
        --image ${DIR_ABS_OUT}/vendor.img \
        --partition_size ${vendor_partition_size} \
        --partition_name vendor \
        --prop com.android.build.vendor.fingerprint:${build_fingerprint} \
        --prop com.android.build.boot.os_version:R

    rm -fr "${DIR_ABS_OUT}/super" && mkdir -p "${DIR_ABS_OUT}/super"
    cat > "${DIR_ABS_OUT}/super/misc_info.txt" <<__EOF__
use_dynamic_partitions=true
lpmake=lpmake
build_super_partition=true
super_metadata_device=super
super_block_devices=super
super_super_device_size=${super_partition_size}
dynamic_partition_list=${super_partition_group_list}
super_partition_groups=${super_partition_group_name}
super_${super_partition_group_name}_group_size=${super_partition_group_size}
super_${super_partition_group_name}_partition_list=${super_partition_group_list}
super_partition_size=${super_partition_size}
system_image=${DIR_ABS_OUT}/system.img
vendor_image=${DIR_ABS_OUT}/vendor.img
super_image_in_update_package=true
ab_update=true
__EOF__

    PATH=${DIR_ABS_LINARO_HOST_BIN}:$PATH ${DIR_ABS_LINARO_HOST_BIN}/build_super_image -v  \
        ${DIR_ABS_OUT}/super/misc_info.txt \
        ${DIR_ABS_OUT}/super.img

    #lpmake \
    #    --metadata-size 65536 \
    #    --super-name super \
    #    --metadata-slots 3 \
    #    --device super:2684354560 \
    #    --group group_oem_a:1341652992 \
    #    --group group_oem_b:1341652992 \
    #    --partition system_a:readonly:866193408:group_oem_a --image system_a=${DIR_ABS_OUT}/system.img --partition system_b:readonly:0:group_oem_b \
    #    --partition vendor_a:readonly:33648640:group_oem_a --image vendor_a=${DIR_ABS_OUT}/vendor.img --partition vendor_b:readonly:0:group_oem_b \
    #    --sparse --output ${DIR_ABS_OUT}/super.img

    # leave for vbmeta.img
    #rm -f ${DIR_ABS_OUT}/system.img
    #rm -f ${DIR_ABS_OUT}/vendor.img
    rm -fr ${DIR_ABS_OUT}/super.img.xz
    xz -T0 ${DIR_ABS_OUT}/super.img
}

func_generate_am65x_kernel_config=am65x_generate_kernel_config
func_create_am65x_boot_fit_img=am65x_create_boot_fit_img
func_create_am65x_vendor_img=ti_create_vendor_img

func_generate_x15_kernel_config=x15_generate_kernel_config
func_create_x15_boot_fit_img=x15_create_boot_fit_img
func_create_x15_vendor_img=ti_create_vendor_img

func_generate_x15_mainline_kernel_config=x15_mainline_generate_kernel_config
func_create_x15_mainline_boot_fit_img=x15_mainline_create_boot_fit_img
func_create_x15_mainline_vendor_img=x15_mainline_ti_create_vendor_img

func_create_x15_super_4_19_boot_img_xz=x15_create_boot_img_4_19
func_create_x15_super_4_19_dtbo_img_xz=x15_dtbo_img_4_19
func_create_x15_super_4_19_super_img_xz=x15_create_super_img
func_create_x15_super_4_19_vbmeta_img_xz=x15_create_vbmeta_img

func_generate_x15_super_5_4_kernel_config=x15_mainline_generate_kernel_config
func_create_x15_super_5_4_boot_img_xz="x15_create_boot_img_4_19 44000000.ocp/48000000.interconnect/48000000.interconnect:segment@0/480b4000.target-module/480b4000.mmc"
func_create_x15_super_5_4_super_img_xz="x15_create_super_img fstab.beagle_x15board_v5"
func_create_x15_super_5_4_vbmeta_img_xz="x15_create_vbmeta_img false"

# from 5.13, the emmc device path under /sys/bus/platform/devices are changed because of the following to changes:
#   ecb4c5c0961b ("ARM: dts: Configure simple-pm-bus for dra7 l3")
#   7f2659ce657e ("ARM: dts: Move dra7 l3 noc to a separate node") --> this is the root cause one
func_generate_x15_super_mainline_kernel_config=x15_mainline_generate_kernel_config
func_create_x15_super_mainline_boot_img_xz="x15_create_boot_img_4_19 ocp/48000000.interconnect/48000000.interconnect:segment@0/480b4000.target-module/480b4000.mmc"
func_create_x15_super_mainline_super_img_xz="x15_create_super_img fstab.beagle_x15board_v5_13"
func_create_x15_super_mainline_vbmeta_img_xz="x15_create_vbmeta_img false"
