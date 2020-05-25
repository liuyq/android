#!/bin/bash -ex


function download_till_finished(){
    local img_url=$1 && shift

    while ! wget --max-redirect 50 -c ${img_url}; do
        sleep 30
    done
}

function download_linaro_ci_prebuilts(){
    local url_build=$1 && shift
    local f_list="list.html"
    local url_snapshots="https://snapshots.linaro.org/"
    wget "https://snapshots.linaro.org/${url_build}" -O ${f_list}

    url_files=$(grep "<a href=\"/${url_build}/" ${f_list} |cut -d\" -f2|grep -v "/$")

    mkdir -p ${url_build}
    cd ${url_build}
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
    cd ${old_pwd}
}

function download_vts(){
    local build_num=$1 && shift
    local branch="aosp-master-throttled"
    local dir_target="${branch}/${build_num}/test_suites_arm64"
    mkdir -p "${dir_target}"
    local old_pwd=${PWD}
    cd ${dir_target}

    local url="https://ci.android.com/builds/submitted/${build_num}/test_suites_arm64/latest/raw/"
    echo ${url} >url.txt

    #download_till_finished ${url}/android-cts.zip
    download_till_finished ${url}/android-vts.zip
    download_till_finished ${url}/manifest_${build_num}.xml
    cp manifest_${build_num}.xml pinned-manifest.xml

    cd ${old_pwd}
}

function download_aosp_master_db845c(){
    local build_num=$1 && shift
    local branch="aosp-master"

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
    rm -f ${lpunpack_files}
    unzip otatools.zip ${lpunpack_files}

    rm -f super.img userdata.img
    unzip db845c-img-${build_num}.zip super.img userdata.img

    rm -f super-raw.img
    ./bin/simg2img super.img super-raw.img

    rm -f product.img system.img system_ext.img vendor.img
    rm -f product.img.xz system.img.xz system_ext.img.xz vendor.img.xz
    ./bin/lpunpack -p product -p system -p system_ext -p vendor super-raw.img
    for f in product.img system.img system_ext.img vendor.img; do
        xz -T 0 $f
    done

    rm -f super-raw.img super.img
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

    rm -f super.img userdata.img recovery.img
    unzip ${board}-img-${build_num}.zip super.img userdata.img recovery.img

    rm -f super-raw.img
    ./bin/simg2img super.img super-raw.img

    rm -f system_a.img system.img vendor_a.img vendor.img
    ./bin/lpunpack -p system_a -p vendor_a super-raw.img
    mv -f system_a.img system.img
    mv -f vendor_a.img vendor.img

    rm -f system.img.xz vendor.img.xz recovery.img.xz
    for f in system.img vendor.img recovery.img; do
        xz -T 0 $f
    done

    rm -f super-raw.img super.img
    cd -
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
    # download_google_ci_prebuilts ${build_num} "beagle_x15"
    cd ${old_pwd}

    for board in hikey hikey960; do
        cd ${branch}/${build_num}/${board}-userdebug

        local img_files="boot.img system.img vendor.img userdata.img"
        rm -f ${img_files}
        unzip ${board}-img-${build_num}.zip ${img_files}

        for f in ${img_files}; do
            rm -f ${f}.xz
            xz -T 0 $f
        done

        cd -
   done
}

function download_android10_gsi(){
    local build_num=$1 && shift
    local branch=aosp-android10-gsi

    mkdir -p ${branch}/${build_num}
    local old_pwd=${PWD}
    cd ${branch}/${build_num}
    echo "https://ci.android.com/builds/branches/${branch}/grid?head=${build_num}&tail=${build_num}" >url.txt

    download_google_ci_prebuilts ${build_num} "aosp_arm64"

    cd ${old_pwd}

    cd ${branch}/${build_num}/aosp_arm64-userdebug
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

    ANDROID_IMAGE_FILES="boot.img dtb.img dtbo.img super.img vbmeta.img userdata.img ramdisk.img ramdisk-debug.img"
    for img in ${ANDROID_IMAGE_FILES}; do
        download_till_finished ${base_url}/4.14-${img}.xz
    done
    for img in ${ANDROID_IMAGE_FILES}; do
        download_till_finished ${base_url}/4.19-${img}.xz
    done
    for img in ${ANDROID_IMAGE_FILES}; do
        download_till_finished ${base_url}/aosp-${img}.xz
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

#    rm -f linaro-cp.py
#        --no-build-info \
#    wget https://git.linaro.org/ci/publishing-api.git/plain/linaro-cp.py -O linaro-cp.py
    python ./linaro-cp.py \
        ${url_build} \
        lkft/aosp-stable/${url_build} \
        --server=https://testdata.linaro.org/
}

#download_throttled_x15 6390383
#download_vts 6524388
#download_throttled_copped 6524047
#download_aosp_master_db845c 6524104
#download_android10_gsi 6508875
#download_lkft_aosp_master_x15 107
download_linaro_ci_prebuilts "android/android-cts/aosp-arm64-userdebug/33/master"


#copy_to_testdata aosp-master/6485810/db845c-userdebug
#copy_to_testdata aosp-master-throttled-copped/6485711
#copy_to_testdata "android/android-cts/aosp-arm64-userdebug/26/master"
#copy_to_testdata aosp-master-throttled/6349140
#copy_to_testdata aosp-android10-gsi/6429841
