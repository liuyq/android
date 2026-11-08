#!/bin/bash -ex

if [ -f ~/.config/linaro-credentials ]; then
    source ~/.config/linaro-credentials
fi
export TUXSUITE_TOKEN

set -o pipefail

DIR_PARENT=$(cd $(dirname $0); pwd)
#url_manifest_kernel="/home/liuyq/data/android/aosp-mirror/kernel/manifest.git"
#url_repo_tools="/home/liuyq/data/android/aosp-mirror/tools/repo.git"
url_manifest_kernel="https://aosp.tuna.tsinghua.edu.cn/kernel/manifest.git"
#url_repo_tools="https://mirrors.tuna.tsinghua.edu.cn/git/git-repo"
#url_manifest_kernel="https://android.googlesource.com/kernel/manifest.git"
#url_repo_tools="https://android.googlesource.com/git/git-repo"
#opt_mirror="-m ssh://prodesk/home/liuyq/data/android/aosp-mirror/kernel/manifest"
#url_manifest_kernel="http://192.168.1.78/git/kernel/manifest.git"
#url_manifest_kernel="https://android-git.linaro.org/git/kernel/manifest.git"
opt_mirror="-m ${url_manifest_kernel}"
#opt_repo="--repo-url ${url_repo_tools}"

configs=""

## reference update

#export X15_SUPPORT_LCD=true
#configs="${configs} lkft-x15-aosp-master-mainline"
#configs="${configs} lkft-hikey-aosp-master-mainline-gki"
#export image_gz_reference_url="${DIR_PARENT}/out/lkft-gki-android-mainline/Image.gz"
#export image_gz_reference_url="https://storage.tuxsuite.com/public/linaro/lkft-android/oebuilds/2LClMl21Dtzrqtp5NS2we3PEHyO/Image.gz"
#configs="${configs} lkft-gki-android-mainline"
#configs="${configs} lkft-db845c-aosp-master-mainline-gki"
#export BUILD_REFERENCE_IMAGE_GZ_URL="https://storage.tuxsuite.com/public/linaro/yongqin/oebuilds/2DNJphU02WHW1brDXndNCWmGIf1/Image.gz"
#export TUXSUITE_BAKE_VENDOR_DOWNLOAD_URL="https://storage.tuxsuite.com/public/linaro/yongqin/oebuilds/2DNNIhqnw2n7WmDEp9nPNsqlinI"
#export BUILD_REFERENCE_IMAGE_GZ_URL=https://storage.tuxsuite.com/public/linaro/lkft-android/oebuilds/2HEJljQ6EXpQYOM12OhU9zdm227/Image.gz
configs="${configs} lkft-hikey960-aosp-master-mainline-gki"

export TUXSUITE_TOKEN
#export USE_GUESTFISH=true
export SKIP_SYNC=true
export SKIP_SYNC=false
export SKIP_MRPROPER=1
#export LTO=none #[full|thin|none]
export BUILD_KERNEL_WITH_UPSTREAM_BUILD=true
function build_config(){
    for c in ${configs}; do
        if [ -n "${BUILD_REFERENCE_IMAGE_GZ_URL}" ]; then
            export BUILD_REFERENCE_IMAGE_GZ_URL
        elif  ! echo $c |grep -q '^lkft-gki-android'; then
            export BUILD_REFERENCE_IMAGE_GZ_URL=${image_gz_reference_url}
        else
            # for gki kernel build
            unset BUILD_REFERENCE_IMAGE_GZ_URL
        fi

        if echo $c |grep -q 'lkft-eap-' ; then
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
}

function build_bisects(){
    commits=""
    #commits="${commits} 71934a02dbca"
    #commits="${commits} cdef824f3de0"
    #commits="${commits} e5e65575783e"
    #commits="${commits} 32f64e53cfdc"
    #commits="${commits} c1815e9bf121"
    #commits="${commits} 20b92b3c9fa5"
    #commits="${commits} 30b7ec16c117"
    #commits="${commits} c58d59e9d494"
    #commits="${commits} a8a61755f677"
    #commits="${commits} 9bf4e4620ecc"

    #commits="${commits} dc73f3eab1af"
    #commits="${commits} faed5a25d92b" #
    #commits="${commits} 0bbe66a90b4f"
    #commits="${commits} d80f39a5aed7"
    #commits="${commits} dcb6f7c7211a"
    #commits="${commits} a0695ef8984c"
    #commits="${commits} 81ce9a434387"
    #commits="${commits} dd1740e7420f"
    #commits="${commits} 18055715b2e9"
#    commits="${commits} f6bfcb34b30c" # not work

#    commits="${commits} cdd23c753171"
#    commits="${commits} e43c2266f3b2" # not work
#    commits="${commits} 7e0806eae138" # not work

#    commits="${commits} f3170cbba601" ANDROID: update PCI dwc vendor entries sort order in gki_defconfig
    commits="${commits} e5638d1c2443" # Merge "Merge b02847fc2e7a ("Merge tag 'firewire-6.4-rc1' of git://git.kernel.org/pub/scm/linux/kernel/git/ieee1394/linux1394") into android-mainline" into android-mainline
    commits="${commits} c9440d6849be" # Merge "Merge b68ee1c6131c ("Merge tag 'scsi-misc' of git://git.kernel.org/pub/scm/linux/kernel/git/jejb/scsi") into android-mainline" into android-mainline
    commits="${commits} c0bb6216f7f2" # not work (db845c-drm-ng-2) Merge "Merge 0cfd8703e7da ("Merge tag 'pm-6.4-rc1' of git://git.kernel.org/pub/scm/linux/kernel/git/rafael/linux-pm") into android-mainline" into android-mainline
#    commits="${commits} 42f0514a17ed" work
#    commits="${commits} 3f6711f547cf" work
#    commits="${commits} 311db2be5ed4"
#    commits="${commits} 3ee567fc882c" # work
#    commits="${commits} 988af76d5251"
#    commits="${commits} 2a4fc73f7eb9" # work
#    commits="${commits} 5353cbb84fd8" # work

    f_build_config="lkft-hikey960-aosp-master-mainline-gki"
    for commit in ${commits}; do
        export SRCREV_kernel="${commit}"
        build_config || true
        mv "out/${f_build_config}" "out/${f_build_config}-${commit}"
    done
}
build_bisects
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

