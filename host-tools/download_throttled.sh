#!/bin/bash -ex


function download_till_finished(){
    local img_url=$1 && shift

    while ! wget -c ${img_url}; do
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
    old_pwd=${PWD}
    cd ${board}-userdebug

    echo "https://ci.android.com/builds/submitted/${build_num}/${board}-userdebug/latest/">url.txt
    download_till_finished https://ci.android.com/builds/submitted/${build_num}/${board}-userdebug/latest/${board}-img-${build_num}.zip
    download_till_finished https://ci.android.com/builds/submitted/${build_num}/${board}-userdebug/latest/ramdisk-debug.img
    download_till_finished https://ci.android.com/builds/submitted/${build_num}/${board}-userdebug/latest/ramdisk.img
    cd ${old_pwd}
}

function download_cts_vts(){
    local build_num=$1 && shift
    local branch="aosp-master"
    local dir_target="${branch}/${build_num}/test_suites_arm64"
    mkdir -p "${dir_target}"
    old_pwd=${PWD}
    cd ${dir_target}

    local url="https://ci.android.com/builds/submitted/${build_num}/test_suites_arm64/latest/"
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
    old_pwd=${PWD}
    cd ${branch}/${build_num}
    echo "https://ci.android.com/builds/branches/${branch}/grid?head=${build_num}&tail=${build_num}" >url.txt

    download_google_ci_prebuilts ${build_num} "db845c"

    cd ${old_pwd}
}

function download_throttled(){
    local build_num=$1 && shift
    local branch=aosp-master-throttled

    mkdir -p ${branch}/${build_num}
    old_pwd=${PWD}
    cd ${branch}/${build_num}
    echo "https://ci.android.com/builds/branches/${branch}/grid?head=${build_num}&tail=${build_num}" >url.txt

    download_google_ci_prebuilts ${build_num} "beagle_x15"

    cd ${old_pwd}
}

function download_throttled_copped(){
    local build_num=$1 && shift
    local branch=aosp-master-throttled-copped

    mkdir -p ${branch}/${build_num}
    old_pwd=${PWD}
    cd ${branch}/${build_num}
    echo "https://ci.android.com/builds/branches/${branch}/grid?head=${build_num}&tail=${build_num}" >url.txt

    download_google_ci_prebuilts ${build_num} "hikey960"
    download_google_ci_prebuilts ${build_num} "hikey"
    # download_google_ci_prebuilts ${build_num} "beagle_x15"
    cd ${old_pwd}
}

function download_android10_gsi(){
    local build_num=$1 && shift
    local branch=aosp-android10-gsi

    mkdir -p ${branch}/${build_num}
    old_pwd=${PWD}
    cd ${branch}/${build_num}
    echo "https://ci.android.com/builds/branches/${branch}/grid?head=${build_num}&tail=${build_num}" >url.txt

    download_google_ci_prebuilts ${build_num} "aosp_arm64"

    cd ${old_pwd}
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

    rm -f linaro-cp.py
    wget https://git.linaro.org/ci/publishing-api.git/plain/linaro-cp.py -O linaro-cp.py
    python ./linaro-cp.py \
        ${url_build} \
        lkft/aosp-stable/${url_build} \
        --server=https://testdata.linaro.org/
}
#download_throttled_copped 6177515
#download_cts_vts 6177848
#download_android10_gsi 6177234
#download_linaro_ci_prebuilts "android/android-cts/aosp-arm64-userdebug/26/master"
#download_linaro_ci_prebuilts "96boards/dragonboard845c/linaro/aosp-master/221"

# 2020-03-03
#download_throttled_copped 6253847
#download_android10_gsi 6254317
#download_linaro_ci_prebuilts "android/android-cts/aosp-arm64-userdebug/27/master"
#download_aosp_master_db845c 6255386
download_cts_vts 6242127
#download_linaro_ci_prebuilts "96boards/dragonboard845c/linaro/aosp-master/229"

#copy_to_testdata aosp-master-throttled-copped/6177515
#copy_to_testdata aosp-master/6177848
#copy_to_testdata aosp-android10-gsi/6177234
#copy_to_testdata "android/android-cts/aosp-arm64-userdebug/26/master"
#copy_to_testdata 96boards/dragonboard845c/linaro/aosp-master/209
