#!/bin/bash -ex

#export SRCREV_kernel=50533a8b511b # 5.4.249-50533a8b511b work
#export SRCREV_kernel=c83e2462239e # 5.4.249-c83e2462239e not work

#export SRCREV_kernel=5779339cae2f # UPSTREAM: f2fs: revert summary entry count from 2048 to 512 in 16kb block support
#export SRCREV_kernel=888797b4f659 # UPSTREAM: f2fs: fix to detect recoverable inode during dryrun of find_fsync_dnodes()


export SKIP_SYNC=true
export SKIP_SYNC=false
#export REFERENCE_BUILD_URL=http://192.168.1.14:8000/android/lkft/lkft-aosp-android11-hikey/2010/
#export REFERENCE_BUILD_URL=http://192.168.1.14:8000/android/lkft/lkft-aosp-android12-hikey/2054/
#export REFERENCE_BUILD_URL=/data/android13/android13/out/target/product/hikey
#export REFERENCE_BUILD_URL_SYSTEM_IMG_XZ=http://192.168.1.14:8000/aosp-android11-gsi/11328968/aosp_arm64-userdebug/system.img.xz
#export REFERENCE_BUILD_URL_USERDEBUG_PLAT_SEPOLICY_CIL=http://192.168.1.14:8000/aosp-android13-gsi/11206184/aosp_arm64-userdebug/userdebug_plat_sepolicy.cil


if [ -f ~/.config/linaro-credentials ]; then
    source ~/.config/linaro-credentials
fi
export TUXSUITE_TOKEN

set -o pipefail

DIR_PARENT=$(cd $(dirname $0); pwd)
url_manifest_kernel="https://aosp.tuna.tsinghua.edu.cn/kernel/manifest.git"
#url_manifest_kernel="https://android.googlesource.com/kernel/manifest.git"
#url_manifest_kernel="https://android-git.linaro.org/git/kernel/manifest.git"
if [ -n "${url_manifest_kernel}" ]; then
    opt_mirror="-m ${url_manifest_kernel}"
fi
#url_repo_tools="/home/liuyq/data/android/aosp-mirror/tools/repo.git"
#url_repo_tools="https://mirrors.tuna.tsinghua.edu.cn/git/git-repo"
#url_repo_tools="https://android.googlesource.com/git/git-repo"
#opt_repo="--repo-url ${url_repo_tools}"

configs=""

## reference update
#configs="${configs} lkft-hikey-aosp-master-4.14-stable-lkft"
#configs="${configs} lkft-hikey960-aosp-master-4.14-stable-lkft"

#configs="${configs} lkft-hikey-aosp-master-4.19-stable-lkft"
#configs="${configs} lkft-hikey-android11-mastergsi-4.19-stable-lkft"
#configs="${configs} lkft-hikey960-android11-4.19-stable-lkft"
#configs="${configs} lkft-hikey960-aosp-master-4.19-stable-lkft"

#configs="${configs} lkft-hikey-android11-4.19-stable-lkft"
#configs="${configs} lkft-hikey-android12-4.19-stable-lkft"
#configs="${configs} lkft-hikey-android12-android13gsi-4.19-stable-lkft"

#configs="${configs} lkft-hikey960-android13-4.14-stable-lkft"
#configs="${configs} lkft-hikey960-android13-4.19-stable-lkft"

#image_gz_reference_url="${DIR_PARENT}/out/lkft-gki-android11-5.4/Image.gz"
#configs="${configs} lkft-gki-android11-5.4"
#configs="${configs} lkft-db845c-android11-android11-5.4-gki"
#configs="${configs} lkft-hikey-android11-android11-5.4-gki"
#configs="${configs} lkft-hikey960-android11-android11-5.4-gki"
#configs="${configs} lkft-hikey960-android12-android11-5.4-gki"
#configs="${configs} lkft-db845c-android12-android11-5.4-gki"
#configs="${configs} lkft-db845c-android13-android11-5.4-gki"
#configs="${configs} lkft-hikey960-aosp-master-android11-5.4-gki"
#configs="${configs} lkft-db845c-aosp-master-android11-5.4-gki"
#configs="${configs} lkft-db845c-android11-android12gsi-android11-5.4-gki"
#configs="${configs} lkft-hikey960-android11-android12gsi-android11-5.4-gki"


#image_gz_reference_url="${DIR_PARENT}/out/lkft-gki-android11-5.4-lts/Image.gz"
#configs="${configs} lkft-gki-android11-5.4-lts"
#configs="${configs} lkft-db845c-android11-android11-5.4-lts-gki"
#configs="${configs} lkft-hikey960-android11-android11-5.4-lts-gki"

#configs="${configs} lkft-hikey-aosp-master-4.14-stable-lkft"
#configs="${configs} lkft-hikey-aosp-master-4.19-stable-lkft"
#configs="${configs} lkft-hikey-aosp-master-mainline-gki"
#configs="${configs} lkft-hikey960-android11-4.14-stable-lkft"
#configs="${configs} lkft-hikey960-android11-android12gsi-4.14-stable-lkft"
#configs="${configs} lkft-hikey960-android11-android13gsi-4.14-stable-lkft"
#configs="${configs} lkft-hikey960-android11-mastergsi-4.14-stable-lkft"
#configs="${configs} lkft-hikey960-android12-4.14-stable-lkft"
#configs="${configs} lkft-hikey960-aosp-master-4.14-stable-lkft"

#configs="${configs} lkft-hikey960-android11-android12gsi-4.19-stable-lkft"
#configs="${configs} lkft-hikey960-android11-android13gsi-4.19-stable-lkft"
#configs="${configs} lkft-hikey960-android11-mastergsi-4.19-stable-lkft"
#configs="${configs} lkft-hikey960-android12-android13gsi-4.19-stable-lkft"
#configs="${configs} lkft-hikey960-android12-mastergsi-4.19-stable-lkft"
#configs="${configs} lkft-hikey960-aosp-master-4.19-stable-lkft"

#export X15_SUPPORT_LCD=true
#configs="${configs} lkft-x15-aosp-master-mainline"
#configs="${configs} lkft-hikey-aosp-master-mainline-gki"
#export image_gz_reference_url="${DIR_PARENT}/out/lkft-gki-android-mainline/Image.gz"
#export image_gz_reference_url="https://storage.tuxsuite.com/public/linaro/lkft-android/oebuilds/2LClMl21Dtzrqtp5NS2we3PEHyO/Image.gz"
#configs="${configs} lkft-gki-android-mainline"
#configs="${configs} lkft-db845c-aosp-master-mainline-gki"
#configs="${configs} lkft-db845c-aosp-master-mainline-gki-for-test"
#configs="${configs} lkft-db845c-aosp-master-mainline-gki-bisect"
#configs="${configs} lkft-db845c-aosp-master-mainline-gki-sdcard"
#configs="${configs} lkft-db845c-aosp-master-mainline-gki-sdcard-debug"
#configs="${configs} lkft-sm8550-aosp-master-mainline-gki-sdcard"
#configs="${configs} lkft-private-sm8550-aosp-master-mainline-gki-sdcard"
#configs="${configs} lkft-db845c-aosp-master-mainline-gki-debug"
#export BUILD_REFERENCE_IMAGE_GZ_URL="https://storage.tuxsuite.com/public/linaro/yongqin/oebuilds/2DNJphU02WHW1brDXndNCWmGIf1/Image.gz"
#export TUXSUITE_BAKE_VENDOR_DOWNLOAD_URL="https://storage.tuxsuite.com/public/linaro/yongqin/oebuilds/2DNNIhqnw2n7WmDEp9nPNsqlinI"
#export BUILD_REFERENCE_IMAGE_GZ_URL=https://storage.tuxsuite.com/public/linaro/lkft-android/oebuilds/2HEJljQ6EXpQYOM12OhU9zdm227/Image.gz
#configs="${configs} lkft-hikey960-aosp-master-mainline-gki"
#configs="${configs} lkft-hikey960-aosp-master-mainline-gki-debug"

#configs="${configs} lkft-x15-aosp-master-4.19-stable-lkft"
#configs="${configs} lkft-hikey-aosp-master-4.19-stable-lkft"
#configs="${configs} lkft-hikey960-android11-mastergsi-4.19-stable-lkft"


#configs="${configs} lkft-hikey-aosp-master-5.4-gki"
#configs="${configs} lkft-x15-aosp-master-android12-5.4"
#image_gz_reference_url="${DIR_PARENT}/out/lkft-gki-android12-5.4/Image.gz"
#configs="${configs} lkft-gki-android12-5.4"
#configs="${configs} lkft-hikey960-aosp-master-android12-5.4-gki"
#configs="${configs} lkft-hikey960-android12-android12-5.4-gki"
#configs="${configs} lkft-hikey-android12-android12-5.4-gki"
#configs="${configs} lkft-hikey960-android12-android12-5.4-gki"
#configs="${configs} lkft-db845c-aosp-master-android12-5.4-gki"
#configs="${configs} lkft-db845c-android12-android12-5.4-gki"
#configs="${configs} lkft-db845c-android11-android12-5.4-gki"

#image_gz_reference_url="${DIR_PARENT}/out/lkft-gki-android12-5.4-lts/Image.gz"
#configs="${configs} lkft-gki-android12-5.4-lts"
#configs="${configs} lkft-db845c-android12-android12-5.4-lts-gki"
#configs="${configs} lkft-hikey960-android12-android12-5.4-lts-gki"

#image_gz_reference_url="http://snapshots.linaro.org/android/lkft/lkft-gki-kernel/1122/lkft-gki-android12-5.10-Image.gz"
#image_gz_reference_url="https://storage.tuxsuite.com/public/linaro/lkft-android/oebuilds/2uIrU749GTaQA1X8KA5BaVMNPyA/Image.gz"
#image_gz_reference_url="${DIR_PARENT}/out/lkft-gki-android12-5.10/Image.gz"
#configs="${configs} lkft-gki-android12-5.10"
#configs="${configs} lkft-hikey960-android12-android12-5.10-gki"
#configs="${configs} lkft-db845c-android12-android12-5.10-gki"
#configs="${configs} lkft-db845c-android13-android12-5.10-gki"
#configs="${configs} lkft-db845c-aosp-master-android12-5.10-gki"
#configs="${configs} lkft-hikey960-aosp-master-android12-5.10-gki"
#configs="${configs} lkft-hikey960-android12-android13gsi-android12-5.10-gki"

#image_gz_reference_url="${DIR_PARENT}/out/lkft-gki-android12-5.10-lts/Image.gz"
#configs="${configs} lkft-gki-android12-5.10-lts"
#configs="${configs} lkft-db845c-android12-android12-5.10-lts-gki"
#configs="${configs} lkft-hikey960-android12-android12-5.10-lts-gki"

#image_gz_reference_url="${DIR_PARENT}/out/lkft-gki-android13-5.10/Image.gz"
#configs="${configs} lkft-gki-android13-5.10"
#configs="${configs} lkft-db845c-android15-android13-5.10-gki"
#configs="${configs} lkft-db845c-aosp-master-android13-5.10-gki"
#configs="${configs} lkft-hikey960-android13-android13-5.10-gki"
#configs="${configs} lkft-hikey960-aosp-master-android13-5.10-gki"
#configs="${configs} lkft-db845c-android13-android13-5.10-gki"

#image_gz_reference_url="${DIR_PARENT}/out/lkft-gki-android13-5.10-lts/Image.gz"
#configs="${configs} lkft-gki-android13-5.10-lts"
#configs="${configs} lkft-db845c-aosp-master-android13-5.10-lts-gki"

#image_gz_reference_url="${DIR_PARENT}/out/lkft-gki-android13-5.15-lts/Image.gz"
#configs="${configs} lkft-gki-android13-5.15-lts"
#configs="${configs} lkft-db845c-aosp-master-android13-5.15-lts-gki"

#image_gz_reference_url="${DIR_PARENT}/out/lkft-gki-android13-5.15/Image.gz"
#configs="${configs} lkft-gki-android13-5.15"
#configs="${configs} lkft-db845c-android15-android13-5.15-gki"
#configs="${configs} lkft-db845c-aosp-master-android13-5.15-gki"
#configs="${configs} lkft-db845c-android13-android13-5.15-gki"

#image_gz_reference_url="${DIR_PARENT}/out/lkft-gki-android14-5.15/Image.gz"
#configs="${configs} lkft-gki-android14-5.15"
#configs="${configs} lkft-db845c-aosp-master-android14-5.15-gki"
#configs="${configs} lkft-db845c-aosp-master-android14-6.1-gki"

#configs="${configs} lkft-x14-aosp-master-4.14-stable-lkft"
#configs="${configs} lkft-x15-aosp-master-4.19-stable-lkft"
#configs="${configs} lkft-x15-aosp-master-4.19"
#configs="${configs} lkft-x15-aosp-master-android12-5.4"
#configs="${configs} lkft-x15-aosp-master-mainline"

#configs="${configs} lkft-eap-db845c-android14-android14-5.15-gki"
#configs="${configs} lkft-eap-db845c-android14-android14-6.1-gki"

#configs="${configs} lkft-db845c-aosp-master-android14-5.15-gki"
#configs="${configs} lkft-db845c-aosp-master-android14-5.15-lts-gki"
#configs="${configs} lkft-db845c-aosp-master-android14-6.1-lts-gki"
#configs="${configs} lkft-db845c-aosp-master-android15-6.1-gki"

#configs="${configs} lkft-gki-android15-6.6"
#configs="${configs} lkft-db845c-android15-android15-6.6-gki"
#configs="${configs} lkft-db845c-aosp-master-android15-6.6-gki"
#configs="${configs} lkft-db845c-aosp-master-android15-6.6-gki-debug"

#configs="${configs} lkft-db845c-android14-android13-5.10-gki"
#configs="${configs} lkft-db845c-android14-android13-5.15-gki"
#configs="${configs} lkft-db845c-android14-android14-5.15-gki"
#configs="${configs} lkft-db845c-android14-android14-6.1-gki"

#configs="${configs} lkft-db845c-android15-android14-5.15-gki"
#configs="${configs} lkft-db845c-android15-android14-6.1-gki"

#configs="${configs} lkft-gki-android16-6.12"
#configs="${configs} lkft-db845c-aosp-master-android16-6.12-gki"
#configs="${configs} lkft-gki-android-mainline"
#configs="${configs} lkft-db845c-aosp-master-mainline-gki-16k"
#configs="${configs} lkft-db845c-aosp-master-mainline-gki-sdcard"
#configs="${configs} lkft-db845c-aosp-master-mainline-gki"
#configs="${configs} lkft-db845c-aosp-master-mainline-gki-debug"
#configs="${configs} lkft-sm8550-aosp-master-mainline-gki-sdcard"
#configs="${configs} lkft-sm8550-aosp-master-mainline-gki-sdcard-16k"

#configs="${configs} lkft-private-sm8550-aosp-master-mainline-gki-sdcard"
#configs="${configs} lkft-private-sm8550-aosp-master-mainline-gki-sdcard-16k"
#configs="${configs} lkft-private-sm8550-aosp-master-android16-6.12-gki-sdcard"

#configs="${configs} lkft-db845c-aosp-master-mainline-gki-for-test"
#configs="${configs} lkft-db845c-aosp-master-android16-6.12-gki"
#configs="${configs} lkft-db845c-aosp-master-android16-6.12-gki-sdcard"
#configs="${configs} lkft-db845c-aosp-master-android15-6.6-gki"
#configs="${configs} lkft-db845c-aosp-master-android15-6.6-gki-sdcard"

#configs="${configs} lkft-db845c-android16-android16-6.12-gki"
#configs="${configs} lkft-private-db845c-eap-android16-6.12-gki"
#configs="${configs} lkft-private-db845c-eap-mainline-gki"

#configs="${configs} lkft-db845c-android11-android11-5.4-gki"
#configs="${configs} lkft-db845c-android12-android12-5.10-gki"
#configs="${configs} lkft-db845c-android13-android13-5.15-gki"
#configs="${configs} lkft-db845c-android14-android14-6.1-gki"
#configs="${configs} lkft-db845c-android15-android15-6.6-gki"
#configs="${configs} lkft-db845c-aosp-master-mainline-gki"
#configs="${configs} lkft-hikey960-aosp-master-mainline-gki"

#configs="${configs} lkft-hikey960-aosp-master-android12-5.10-gki"
#configs="${configs} lkft-hikey960-aosp-master-android13-5.10-gki"

#configs="${configs} lkft-db845c-aosp-master-android17-6.18-gki"
#configs="${configs} lkft-db845c-aosp-master-android17-6.18-gki-debug"
configs="${configs} lkft-db845c-aosp-master-android17-6.18-gki-16k"

args_configs="$@"
if [ -n "${args_configs}" ]; then
    configs="${args_configs}"
    unset image_gz_reference_url
fi

export TUXSUITE_TOKEN
#export USE_GUESTFISH=true
export SKIP_MRPROPER=1
export LTO=none #[full|thin|none]
export BUILD_KERNEL_WITH_UPSTREAM_BUILD=true
for c in ${configs}; do
    if [ -n "${BUILD_REFERENCE_IMAGE_GZ_URL}" ]; then
        export BUILD_REFERENCE_IMAGE_GZ_URL
    elif  ! echo $c |grep -q '^lkft-gki-android'; then
        if [ -n "${image_gz_reference_url}" ]; then
            export BUILD_REFERENCE_IMAGE_GZ_URL="${image_gz_reference_url}"
        fi
    else
        # for gki kernel build
        unset BUILD_REFERENCE_IMAGE_GZ_URL
    fi

    if echo $c |grep -q 'lkft-private-' ; then
        rm -f android-build-configs/lkft/${c}
        opt_cu="-cu ${DIR_PARENT}/android-build-configs-private/lkft/${c}"
    fi

    rm -fr out/${c}/vendor-kernel/common/.thinlto-cache/
    rm -fr out/${c}/gki-kernel/common/.thinlto-cache/
    rm -fr out/${c}/vendor-kernel/.thinlto-cache/
    rm -fr out/${c}/gki-kernel/.thinlto-cache/

    mkdir -p build-logs
    echo "config=$c BUILD_REFERENCE_IMAGE_GZ_URL=${BUILD_REFERENCE_IMAGE_GZ_URL}="
    if ${SKIP_SYNC}; then
        #time ./android-build-configs/lkft/linaro-lkft.sh -c ${c} -g 'default,notdefault' -ss 2>&1 |tee build-logs/${c}.log
        #time ./linaro-lkft.sh \
        time ./android-build-configs/lkft/linaro-lkft.sh \
                    -c ${c} \
                    ${opt_mirror} \
                    ${opt_cu} -ss 2>&1 |tee build-logs/${c}.log
    else
        #time ./android-build-configs/lkft/linaro-lkft.sh -c ${c} -g 'default,notdefault' 2>&1 |tee build-logs/${c}.log
        #time ./linaro-lkft.sh \
        time ./android-build-configs/lkft/linaro-lkft.sh \
                    -c ${c} \
                    ${opt_mirror} \
                    ${opt_repo} \
                    ${opt_cu} 2>&1 |tee build-logs/${c}.log

#                    -m "${url_manifest_kernel}" \
#                    --repo-url ${url_repo_tools} \
    fi

    rm -fr out/${c}/vendor-kernel/common/.thinlto-cache/
    rm -fr out/${c}/gki-kernel/common/.thinlto-cache/
    rm -fr out/${c}/vendor-kernel/.thinlto-cache/
    rm -fr out/${c}/gki-kernel/.thinlto-cache/

    imgs="boot.img vendor_boot.img vendor.img system.img userdata.img super.img dtbo.img vbmeta.img cache.img recovery.img"
    for f in ${imgs}; do
        [ -f out/${c}/${f}.xz ] && rm -f out/${c}/${f} && xz -d out/${c}/${f}.xz
    done
done
pactl play-sample dialog-question

exit
Updated via the following method for hikey960:
 $ ./build/abi/bootstrap
 <follow instructions for adding needed path variables>
 $ BUILD_CONFIG=common/build.config.hikey960 build/build.sh
 $ ./build/abi/extract_symbols out/android-5.4/ --whitelist common/abi_gki_aarch64_hikey960_whitelist
 $ BUILD_CONFIG=common/build.config.gki.aarch64 build/build_abi.sh --update --print-report
 $ BUILD_CONFIG=common/build.config.hikey960 build/build_abi.sh --update --print-report

Updated via the following method for db845c:
 $ ./build/abi/bootstrap
 <follow instructions for adding needed path variables>
 $# BUILD_CONFIG=common/build.config.db845c build/build.sh
 $ ./build/abi/extract_symbols out/android12-5.4/ --whitelist common/android/abi_gki_aarch64_db845c
 $ BUILD_CONFIG=common/build.config.gki.aarch64 build/build_abi.sh --update --print-report
 $ BUILD_CONFIG=common/build.config.db845c build/build_abi.sh --update

New method to update abi symbols:
 $ KMI_SYMBOL_LIST_ADD_ONLY=1 BUILD_CONFIG=common/build.config.db845c build/build_abi.sh -s
 $ BUILD_CONFIG=common/build.config.gki.aarch64 build/build_abi.sh -u

