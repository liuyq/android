#!/bin/bash

export BASE=$(cd $(dirname $0);pwd)

source ${BASE}/scripts-common/sync-common.sh

if [ -d /SATA3/aosp-mirror/platform/manifest.git ]; then
    export MIRROR="/SATA3/aosp-mirror/platform/manifest.git"
elif [ -d /home/yongqin.liu/aosp-mirror/platform/manifest.git ]; then
    export MIRROR="/home/yongqin.liu/aosp-mirror/platform/manifest.git"
elif [ -d /development/android/aosp-mirror/platform/manifest.git ]; then
    export MIRROR="/development/android/aosp-mirror/platform/manifest.git"
else
    echo "Please specify value for MIRROR"
    exit 1
fi

branch="master"

LOCAL_MANIFEST="ssh://git@dev-private-git.linaro.org/linaro-art/platform/manifest.git"
LOCAL_MANIFEST_BRANCH="linaro-master"
LOCAL_MANIFEST="https://android-git.linaro.org/git/platform/manifest.git"
LOCAL_MANIFEST_BRANCH="linaro-master"

main "$@"

if true; then
${BASE}/sync-projects.sh  \
                          android-patchsets \
                          android-build-configs \
                          device/linaro/hikey \
                          kernel/linaro/hisilicon/ \
                          frameworks/base \
                          frameworks/av \

#                          bionic \
#                          build \

#${BASE}/sync-projects.sh \
#                        system/extras \
#                        system/vold \
#                        system/core \

${BASE}/sync-projects.sh \
                        external/libdrm \
                        device/ti/am57xevm \

#                        kernel/ti/x15/ \
#                        ti/u-boot/ \
#                          art \
#                          external/opencv-upstream \

${BASE}/sync-projects.sh \
                        external/optee_client \
                        external/optee_test \
                        optee/optee_os \

fi
#export http_proxy=192.168.0.102:37586
#export https_proxy=192.168.0.102:37586

func_apply_patch MASTER-RLCR-PATCHSET
func_apply_patch hikey-master-workarounds
func_apply_patch hikey-optee-master
#func_apply_patch hikey-optee-4.9
func_apply_patch hikey-optee-4.14
#func_apply_patch MASTER-CLANG-PATCHSET
func_apply_patch x15-master-workarounds
func_apply_patch x15-master-workarounds-lcr
#func_apply_patch NOUGAT-BOOTTIME-OPTIMIZATIONS-HIKEY
#func_apply_patch NOUGAT-BOOTTIME-OPTIMIZATIONS-X15
#func_apply_patch NOUGAT-BOOTTIME-OPTIMIZATIONS-JUNO

func_apply_patch optee-master-workarounds
func_apply_patch LIUYQ-PATCHSET

#./build.sh
exit
