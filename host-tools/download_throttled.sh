#!/bin/bash -ex

# https://ci.android.com/builds/branches/aosp-master-throttled-copped/grid?head=6986658&tail=6922500

function download_till_finished(){
    local img_url=$1 && shift
    local target_path=$1

    if [ -z "${target_path}" ]; then
        while ! wget --max-redirect 50 -c ${img_url}; do
            sleep 5
        done
    else
        while ! wget --max-redirect 50 -c ${img_url} -O ${target_path}; do
            sleep 5
        done
    fi
}

function download_linaro_ci_prebuilts(){
    local url_build=$1 && shift
    local f_list="list.html"
    local url_snapshots="https://snapshots.linaro.org/"

    mkdir -p ${url_build}
    cd ${url_build}
    wget "https://snapshots.linaro.org/${url_build}" -O ${f_list}
    url_files=$(grep "<a href=\"/${url_build}/" ${f_list} |cut -d\" -f2|grep -v "/$")

    for url_f in ${url_files}; do
       download_till_finished "${url_snapshots}/${url_f}"
    done
    cd -
}

function download_google_ci_prebuilts(){
    local build_num=$1 && shift
    local board=$1 && shift

    mkdir -p ${board}-userdebug
    local old_pwd=${PWD}
    cd ${board}-userdebug

    echo "https://ci.android.com/builds/submitted/${build_num}/${board}-userdebug/latest/">url.txt
    download_till_finished https://ci.android.com/builds/submitted/${build_num}/${board}-userdebug/latest/raw/${board}-img-${build_num}.zip
    download_till_finished https://ci.android.com/builds/submitted/${build_num}/${board}-userdebug/latest/raw/ramdisk-debug.img
    download_till_finished https://ci.android.com/builds/submitted/${build_num}/${board}-userdebug/latest/raw/ramdisk.img
    download_till_finished https://ci.android.com/builds/submitted/${build_num}/${board}-userdebug/latest/raw/build.prop
    download_till_finished https://ci.android.com/builds/submitted/${build_num}/${board}-userdebug/latest/raw/manifest_${build_num}.xml
    grep ro.system.build.fingerprint build.prop |cut -d= -f2 > build_fingerprint.txt
    cd ${old_pwd}
}

function download_vts_cts(){
    local build_num=$1 && shift
    local branch="aosp-master"
    local dir_target="${branch}/${build_num}/test_suites_arm64"
    mkdir -p "${dir_target}"
    local old_pwd=${PWD}
    cd ${dir_target}

    local url="https://ci.android.com/builds/submitted/${build_num}/test_suites_arm64/latest/raw/"
    echo ${url} >url.txt

    #download_till_finished ${url}/android-cts.zip
    download_till_finished ${url}/android-vts.zip
    download_till_finished ${url}/android-cts.zip
    download_till_finished ${url}/manifest_${build_num}.xml
    cp manifest_${build_num}.xml pinned-manifest.xml

    cd ${old_pwd}
}

function download_aosp_master_db845c(){
    local branch="aosp-master"
    local build_num=$1 && shift
    download_google_db845c "${branch}" "${build_num}"
}

function download_android11_gsi_db845c(){
    local branch="aosp-android11-gsi"
    local build_num=$1 && shift
    download_google_db845c "${branch}" "${build_num}"
}

function download_google_db845c(){
    local branch="$1" && shift
    local build_num=$1 && shift

    mkdir -p ${branch}/${build_num}
    local old_pwd=${PWD}
    cd ${branch}/${build_num}
    echo "https://ci.android.com/builds/branches/${branch}/grid?head=${build_num}&tail=${build_num}" >url.txt

    download_google_ci_prebuilts ${build_num} "db845c"

    cd ${old_pwd}

    cd ${branch}/${build_num}/db845c-userdebug
    local url="https://ci.android.com/builds/submitted/${build_num}/db845c-userdebug/latest/raw"
    download_till_finished ${url}/otatools.zip
    download_till_finished ${url}/super_misc_info.txt

    lpunpack_files="bin/lpunpack bin/simg2img lib64/libbase.so lib64/liblog.so lib64/liblp.so lib64/libsparse-host.so lib64/libc++.so lib64/libcrypto-host.so lib64/libcrypto_utils.so lib64/libext4_utils.so lib64/libz-host.so"
    rm -fr bin lib64
    unzip otatools.zip ${lpunpack_files}

    rm -f android-info.txt super.img userdata.img boot.img cache.img
    unzip db845c-img-${build_num}.zip

    rm -f super-raw.img
    ./bin/simg2img super.img super-raw.img

    for f in product system system_ext vendor; do
        [ -f ${f}.img ] && rm -f ${f}.img
        [ -f ${f}_a.img ] && rm -f ${f}_a.img
        [ -f ${f}_b.img ] && rm -f ${f}_b.img
    done
    ./bin/lpunpack super-raw.img
    for f in product system system_ext vendor; do
        [ -f ${f}_b.img ] && rm -f ${f}_b.img
        [ -f ${f}_a.img ] && mv -v ${f}_a.img ${f}.img
        [ -f ${f}.img ] && rm -f ${f}.img.xz && xz -T 0 ${f}.img
    done

    for f in boot.img super.img userdata.img cache.img; do
        rm -f ${f}.xz
        if [ -f ${f} ]; then
            xz -T 0 $f
        fi
    done

    rm -f super-raw.img
    cd -
}

function download_throttled_x15(){
    local build_num=$1 && shift
    local branch=aosp-master-throttled
    local board="beagle_x15"

    mkdir -p ${branch}/${build_num}
    local old_pwd=${PWD}
    cd ${branch}/${build_num}
    echo "https://ci.android.com/builds/branches/${branch}/grid?head=${build_num}&tail=${build_num}" >url.txt

    download_google_ci_prebuilts ${build_num} "${board}"

    cd ${old_pwd}

    cd ${branch}/${build_num}/${board}-userdebug
    local url="https://ci.android.com/builds/submitted/${build_num}/${board}-userdebug/latest/raw"
    download_till_finished ${url}/otatools.zip
    download_till_finished ${url}/super_misc_info.txt
    download_till_finished ${url}/build.prop

    lpunpack_files="bin/avbtool bin/lpunpack bin/simg2img lib64/libbase.so lib64/liblog.so lib64/liblp.so lib64/libsparse-host.so lib64/libc++.so lib64/libcrypto-host.so lib64/libcrypto_utils.so lib64/libext4_utils.so lib64/libz-host.so"
    rm -f ${lpunpack_files}
    unzip otatools.zip ${lpunpack_files}

    rm -f boot.img vbmeta.img super.img userdata.img recovery.img
    unzip ${board}-img-${build_num}.zip boot.img vbmeta.img super.img userdata.img recovery.img

    rm -f super-raw.img
    ./bin/simg2img super.img super-raw.img

    rm -f system_a.img system.img vendor_a.img vendor.img
    ./bin/lpunpack -p system_a -p vendor_a super-raw.img
    mv -f system_a.img system.img
    mv -f vendor_a.img vendor.img

    for f in boot.img vbmeta.img super.img system.img vendor.img recovery.img userdata.img; do
        rm -f ${f}.xz
        xz -T 0 $f
    done

    rm -f super-raw.img
    cd -
}

function download_throttled_copped_cuttefish(){
    local build_num=$1 && shift
    local branch=aosp-master-throttled-copped

    mkdir -p ${branch}/${build_num}
    local old_pwd=${PWD}
    cd ${branch}/${build_num}
    echo "https://ci.android.com/builds/branches/${branch}/grid?head=${build_num}&tail=${build_num}" >url.txt

    download_google_ci_prebuilts ${build_num} "aosp_cf_arm64_only_phone"
    download_till_finished https://ci.android.com/builds/submitted/${build_num}/${board}-userdebug/latest/raw/cvd-host_package.tar.gz
    cd ${old_pwd}
}

function download_throttled_copped(){
    local build_num=$1 && shift
    local branch=aosp-master-throttled-copped

    mkdir -p ${branch}/${build_num}
    local old_pwd=${PWD}
    cd ${branch}/${build_num}
    echo "https://ci.android.com/builds/branches/${branch}/grid?head=${build_num}&tail=${build_num}" >url.txt

    download_google_ci_prebuilts ${build_num} "hikey960"
    download_google_ci_prebuilts ${build_num} "hikey"
    cd ${old_pwd}

    for board in hikey hikey960; do
        cd ${branch}/${build_num}/${board}-userdebug

        if [ "X${board}X" = "Xhikey960X" ]; then
            local img_files="android-info.txt boot.img super.img userdata.img"
            rm -f ${img_files}
            unzip ${board}-img-${build_num}.zip ${img_files}

            for f in ${img_files}; do
                rm -f ${f}.xz
                xz -T 0 $f
            done
        else
            local img_files="android-info.txt boot.img system.img vendor.img userdata.img"
            rm -f ${img_files}
            unzip ${board}-img-${build_num}.zip ${img_files}

            for f in ${img_files}; do
                rm -f ${f}.xz
                xz -T 0 $f
            done
        fi

        cd -
    done

    if [ "X${board}X" = "Xhikey960X" ]; then
        cd ${branch}/${build_num}/${board}-userdebug
        local url="https://ci.android.com/builds/submitted/${build_num}/${board}-userdebug/latest/raw"
        download_till_finished ${url}/otatools.zip
        #download_till_finished ${url}/super.img
        download_till_finished ${url}/super_misc_info.txt
        download_till_finished ${url}/build.prop

        lpunpack_files="bin/lpunpack bin/simg2img lib64/libbase.so lib64/liblog.so lib64/liblp.so lib64/libsparse-host.so lib64/libc++.so lib64/libcrypto-host.so lib64/libcrypto_utils.so lib64/libext4_utils.so lib64/libz-host.so"
        rm -fr bin lib64
        unzip otatools.zip ${lpunpack_files}

        rm -f super-raw.img
        xz -d super.img.xz
        ./bin/simg2img super.img super-raw.img

        for f in product system system_ext vendor; do
            [ -f ${f}.img ] && rm -f ${f}.img
            [ -f ${f}_a.img ] && rm -f ${f}_a.img
            [ -f ${f}_b.img ] && rm -f ${f}_b.img
        done
        ./bin/lpunpack super-raw.img
        for f in product system system_ext vendor; do
            [ -f ${f}_b.img ] && rm -f ${f}_b.img
            [ -f ${f}_a.img ] && mv -v ${f}_a.img ${f}.img
            [ -f ${f}.img ] && rm -f ${f}.img.xz && xz -T 0 ${f}.img
        done

        for f in boot.img super.img userdata.img; do
            if [ -f ${f} ]; then
                rm -f ${f}.xz
                xz -T 0 $f
            fi
        done
        rm -f super-raw.img

        cd -
   fi
}

function download_master_gsi(){
    local build_num=$1 && shift
    download_gsi "aosp-master" ${build_num}
}

function download_android13_gsi(){
    local build_num=$1 && shift
    download_gsi "aosp-android13-gsi" ${build_num}
}

function download_android12_gsi(){
    local build_num=$1 && shift
    download_gsi "aosp-android12-gsi" ${build_num}
}

function download_android11_gsi(){
    local build_num=$1 && shift
    download_gsi "aosp-android11-gsi" ${build_num}
}

function download_android10_gsi(){
    local build_num=$1 && shift
    download_gsi "aosp-android10-gsi" ${build_num}
}

function download_gsi(){
    local branch=$1 && shift
    local build_num=$1 && shift

    mkdir -p ${branch}/${build_num}
    local old_pwd=${PWD}
    cd ${branch}/${build_num}
    echo "https://ci.android.com/builds/branches/${branch}/grid?head=${build_num}&tail=${build_num}" >url.txt

    download_google_ci_prebuilts ${build_num} "aosp_arm64"

    cd ${old_pwd}

    cd ${branch}/${build_num}/aosp_arm64-userdebug
    local url="https://ci.android.com/builds/submitted/${build_num}/aosp_arm64-userdebug/latest/raw"
    download_till_finished ${url}/otatools.zip
    download_till_finished ${url}/userdebug_plat_sepolicy.cil

    rm -fr system.img system.img.xz
    unzip aosp_arm64-img-${build_num}.zip system.img
    xz -T 0 system.img
    cd -
}

function download_lkft_aosp_master_x15(){
    local build_num=$1 && shift

    local target_dir=android/lkft/lkft-aosp-master-x15/${build_num}
    local base_url=http://snapshots.linaro.org/android/lkft/lkft-aosp-master-x15/${build_num}

    mkdir -p ${target_dir}
    cd ${target_dir}

    ANDROID_IMAGE_FILES="boot.img dtb.img dtbo.img super.img vbmeta.img userdata.img ramdisk.img ramdisk-debug.img recovery.img"
    rm -fr 4.14 4.19 aosp
    mkdir -p 4.14 4.19 aosp
    for img in ${ANDROID_IMAGE_FILES}; do
        download_till_finished ${base_url}/4.14-${img}.xz
        xz -T0 -k -d 4.14-${img}.xz
        mv 4.14-${img} 4.14/${img}
    done
    for img in ${ANDROID_IMAGE_FILES}; do
        download_till_finished ${base_url}/4.19-${img}.xz
        xz -T0 -k -d 4.19-${img}.xz
        mv 4.19-${img} 4.19/${img}
    done
    for img in ${ANDROID_IMAGE_FILES}; do
        download_till_finished ${base_url}/aosp-${img}.xz
        xz -T0 -k -d aosp-${img}.xz
        mv aosp-${img} aosp/${img}
    done
    download_till_finished ${base_url}/u-boot.img
    download_till_finished ${base_url}/MLO
    cd -
}

function copy_to_testdata(){
    if [ -z "${PUBLISH_TOKEN}" ] &&  [ -f ~/.private/linaro ]; then
        source ~/.private/linaro
        export PUBLISH_TOKEN=${PUBLISH_TOKEN}
    fi

    if [ -z "${PUBLISH_TOKEN}" ]; then
        echo "Please set PUBLISH_TOKEN for publish files"
        exit 1
    fi
    #python linaro-cp.py 6004124/hikey-userdebug/ lkft/aosp-stable/aosp-master-throttled/6004124/hikey-userdebug/ --server=https://testdata.linaro.org/
    # https://snapshots.linaro.org/android/android-lcr-reference-am65x-p/61/
    #dir_local=/home/yongqin.liu/public_html/images/x15-auto/pie/9
    #dir_remote=lkft/aosp-stable/android-lcr-reference-x15-p-auto/9
    #dir_local=/home/yongqin.liu/public_html/images/am65x-auto/12
    #dir_remote=lkft/aosp-stable/android-lcr-reference-am65x-p-auto/12

    local url_build=$1 && shift
    local no_build_info=$1

#    rm -f linaro-cp.py
#    wget https://git.linaro.org/ci/publishing-api.git/plain/linaro-cp.py -O linaro-cp.py
    opt_no_build_info=""
    if [ -n "${no_build_info}" ] && [ "X${no_build_info}X" = "XtrueX" ]; then
        opt_no_build_info="--no-build-info"
    fi
    python3 ./linaro-cp.py \
        ${opt_no_build_info} \
        ${url_build} \
        lkft/aosp-stable/${url_build} \
        --server=https://testdata.linaro.org/
}

function download_google_release_cts(){
    local tag="${1}" && shift
    local url="https://dl.google.com/dl/android/cts/${tag}-linux_x86-arm.zip"
    local target_dir="google-released-cts/${tag}"
    mkdir -p ${target_dir}
    cd ${target_dir}
    echo ${url} >url.txt
    download_till_finished ${url} android-cts.zip
    #mv ${tag}-linux_x86-arm.zip android-cts.zip
    cd -
}

function download_hikey960_super_prm_ptable(){
    local url_build=$1 && shift

    mkdir -p "${url_build}"
    url_ptable="https://android-git.linaro.org/android-build-configs.git/plain/lkft/scripts/hikey/prm_ptable-hikey960.img?h=lkft"
    wget -c "${url_ptable}" -O "${url_build}/prm_ptable.img"
}

function download_hikey_uefi_firmware(){
    local build_num="${1}"
    local dir_prefix="reference-platform/components/uefi-staging/"
    local url_prefix="https://snapshots.linaro.org/${dir_prefix}/"
    local url_suffix="/hikey/release/"

    local dir_local="${dir_prefix}/${build_num}/${url_suffix}"
    mkdir -p "${dir_local}"
    cd "${dir_local}"
    for f in MD5SUMS.txt fip.bin hisi-idt.py l-loader.bin nvme.img optee-arm-plat-hikey.tar.xz prm_ptable.img recovery.bin sec_ptable.img ; do
        wget -c "${url_prefix}/${build_num}/${url_suffix}/${f}"
    done
    md5sum -c MD5SUMS.txt || true
    cd -
}
function download_hikey960_uefi_firmware(){
    local build_num="${1}"
    local dir_prefix="reference-platform/components/uefi-staging/"
    local url_prefix="https://snapshots.linaro.org/${dir_prefix}/"
    local url_suffix="/hikey960/release/"

    local dir_local="${dir_prefix}/${build_num}/${url_suffix}"
    mkdir -p "${dir_local}"
    cd "${dir_local}"
    for f in MD5SUMS.txt config fip.bin \
            hikey_idt hisi-sec_uce_boot.img hisi-sec_usb_xloader.img hisi-sec_xloader.img \
            l-loader.bin prm_ptable.img recovery.bin sec_ptable.img ; do
        wget -c "${url_prefix}/${build_num}/${url_suffix}/${f}"
    done
    md5sum -c MD5SUMS.txt || true
    cd -
}

function download_tuxsuite_prebuilts(){
    # tuxsuite url is something like this: https://storage.tuxsuite.com/public/linaro/yongqin/oebuilds/2DD36r5rmUGPzpaeVxm0LYG8Gt2/
    # tuxsuite url is something like this: https://storage.tuxsuite.com/public/linaro/lkft/oebuilds/2fUrAszJQ0dcGROzLdEw8IqGmxT/
    local tuxsuite_download_url="${1}"
    local tuxsuite_download_sha=$(basename "${tuxsuite_download_url}")
    local dir_prebuilts="tuxsuite/${tuxsuite_download_sha}"

    local f_finsihed="${dir_prebuilts}/download_finished"
    if [ ! -f "${f_finsihed}" ]; then
        local url_download=$(dirname "${tuxsuite_download_url}")/$(basename "${tuxsuite_download_url}")
        mkdir -p "${dir_prebuilts}"
        cd "${dir_prebuilts}"
        local f_list="list.json"
        download_till_finished "${url_download}/" "${f_list}"
        local url_files=$(jq -r '.files[].Url' "${f_list}")

        for f_name_or_url in ${url_files}; do
            # according to issue here: https://gitlab.com/Linaro/tuxsuite/-/issues/173
            # for the storage.tuxsuite.com server
            f_name=$(basename "${f_name_or_url}")
            ### TUXSUITE_BAKE_VENDOR_DOWNLOAD_URL might have lava kisscache url
            ### f_name_or_url will not have that
            url_f="${url_download}/${f_name}"
            download_till_finished "${url_f}" "${f_name}"
            if [ "X${f_name}" = "Xramdisk.img.xz" ]; then
                rm -f "ramdisk.img"
                xz -k -d "${f_name}"
            fi
            if [ "X${f_name}" = "Xramdisk-debug.img.xz" ]; then
                rm -f "ramdisk-debug.img"
                xz -k -d "${f_name}"
            fi
        done
        cd -
        touch "${f_finsihed}"
    fi
    local build_name=$(jq -r ".name" "${dir_prebuilts}/build-definition.json")
    local link_prebuilts="tuxsuite/${tuxsuite_download_sha}-${build_name}"
    if [ ! -L "${link_prebuilts}" ]; then
        ln -r -s "${dir_prebuilts}" "${link_prebuilts}"
    fi
}

########## download hikey/hikey960 uefi firmware ########
#download_hikey_uefi_firmware 123
#download_hikey960_uefi_firmware 123
########## upload firmware files #####################
#copy_to_testdata reference-platform/components/uefi-staging/123

########## download aosp master images ########
download_linaro_ci_prebuilts android/lkft/lkft-aosp-main-db845c/2423
#download_linaro_ci_prebuilts android/lkft/lkft-aosp-main-hikey960/2424
download_linaro_ci_prebuilts android/lkft/lkft-aosp-main-linaro-hikey960/2425
download_hikey960_super_prm_ptable android/lkft/lkft-aosp-main-linaro-hikey960/2425
download_linaro_ci_prebuilts android/lkft/lkft-aosp-main-cts/2426
download_linaro_ci_prebuilts android/lkft/lkft-aosp-main-vts/2427
#download_linaro_ci_prebuilts android/lkft/lkft-aosp-main-arm64/2428
########## upload aosp master files #####################
#copy_to_testdata android/lkft/lkft-aosp-main-db845c/2423
#copy_to_testdata android/lkft/lkft-aosp-main-hikey960/2424
#copy_to_testdata android/lkft/lkft-aosp-main-linaro-hikey960/2425
#copy_to_testdata android/lkft/lkft-aosp-main-cts/2426
#copy_to_testdata android/lkft/lkft-aosp-main-vts/2427
#copy_to_testdata android/lkft/lkft-aosp-main-arm64/2428

########## download android14 images ########
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android14-db845c/2420
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android14-cts/2421
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android14-vts/2422
########## upload android13 files #####################
#copy_to_testdata android/lkft/lkft-aosp-android14-db845c/2420
#copy_to_testdata android/lkft/lkft-aosp-android14-cts/2421
#copy_to_testdata android/lkft/lkft-aosp-android14-vts/2422

########## download android13 images ########
download_android13_gsi 11826145
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android13-db845c/2416
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android13-hikey960/2417
download_hikey960_super_prm_ptable android/lkft/lkft-aosp-android13-hikey960/2417
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android13-cts/2418
#download_google_release_cts android-cts-13_r4
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android13-vts/2419
########## upload android13 files #####################
#copy_to_testdata aosp-android13-gsi/11826145/aosp_arm64-userdebug
#copy_to_testdata android/lkft/lkft-aosp-android13-db845c/2416
#copy_to_testdata android/lkft/lkft-aosp-android13-hikey960/2417
#copy_to_testdata android/lkft/lkft-aosp-android13-cts/2418
#copy_to_testdata google-released-cts/android-cts-13_r4
#copy_to_testdata android/lkft/lkft-aosp-android13-vts/2419

########## download android12 images ########
download_android12_gsi 11791118
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android12-hikey/2411
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android12-hikey960/2412
download_hikey960_super_prm_ptable android/lkft/lkft-aosp-android12-hikey960/2412
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android12-db845c/2413
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android12-cts/2414
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android12-vts/2415
########## upload android12 files #####################
#copy_to_testdata aosp-android12-gsi/11791118/aosp_arm64-userdebug
#copy_to_testdata android/lkft/lkft-aosp-android12-hikey/2411
#copy_to_testdata android/lkft/lkft-aosp-android12-hikey960/2412
#copy_to_testdata android/lkft/lkft-aosp-android12-db845c/2413
#copy_to_testdata android/lkft/lkft-aosp-android12-cts/2414
#copy_to_testdata android/lkft/lkft-aosp-android12-vts/2415


########## download android11 images ########
download_android11_gsi_db845c 11718355
download_android11_gsi 11718355
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android11-hikey960/2406
download_hikey960_super_prm_ptable android/lkft/lkft-aosp-android11-hikey960/2406
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android11-hikey/2408
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android11-cts/2409
download_linaro_ci_prebuilts android/lkft/lkft-aosp-android11-vts/2410
########## upload android11 files #####################
#copy_to_testdata aosp-android11-gsi/11718355/aosp_arm64-userdebug
#copy_to_testdata aosp-android11-gsi/11718355/db845c-userdebug
#copy_to_testdata android/lkft/lkft-aosp-android11-hikey960/2406
#copy_to_testdata android/lkft/lkft-aosp-android11-hikey/2408
#copy_to_testdata android/lkft/lkft-aosp-android11-cts/2309
#copy_to_testdata android/lkft/lkft-aosp-android11-vts/2410

## downlaod tuxsuite prebuilts
#download_tuxsuite_prebuilts https://storage.tuxsuite.com/public/linaro/lkft/oebuilds/2fUrAszJQ0dcGROzLdEw8IqGmxT/
#download_tuxsuite_prebuilts https://storage.tuxsuite.com/public/linaro/lkft/oebuilds/2fSiLfQQIAXDUSHN3PwikNzvLPy/
