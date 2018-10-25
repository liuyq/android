#!/bin/bash

export BASE=$(cd $(dirname $0);pwd)

source ${BASE}/scripts-common/sync-common.sh

if [ -d /SATA3/aosp-mirror/platform/manifest.git ]; then
    export MIRROR="/SATA3/aosp-mirror/platform/manifest.git"
elif [ -d /home/yongqin.liu/aosp-mirror/platform/manifest.git ]; then
    export MIRROR="/home/yongqin.liu/aosp-mirror/platform/manifest.git"
elif [ -d /development/android/aosp-mirror/platform/manifest.git ]; then
    export MIRROR="/development/android/aosp-mirror/platform/manifest.git"
elif [ -d /data/android/aosp-mirror/platform/manifest.git ]; then
    export MIRROR="/data/android/aosp-mirror/platform/manifest.git"
else
    echo "Please specify value for MIRROR"
    exit 1
fi

branch="master"

LOCAL_MANIFEST="git://android-git.linaro.org/platform/manifest.git"
LOCAL_MANIFEST_BRANCH="linaro-master"

main "$@"

if false; then
${BASE}/sync-projects.sh  \
                          frameworks/base \
                          system/core \
                          android-patchsets \
                          android-build-configs \
                          device/linaro/hikey \

if [ -d kernel/linaro/hisilicon-4.14 ]; then
    ${BASE}/sync-projects.sh kernel/linaro/hisilicon-4.14
fi
if [ -d kernel/linaro/hisilicon-4.9 ]; then
    ${BASE}/sync-projects.sh kernel/linaro/hisilicon-4.9
fi
if [ -d kernel/linaro/hisilicon-4.4 ]; then
    ${BASE}/sync-projects.sh kernel/linaro/hisilicon-4.4
fi


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
if [ -d kernel/linaro/hisilicon-4.14 ]; then
    func_apply_patch hikey-optee-4.14
fi
if [ -d kernel/linaro/hisilicon-4.9 ]; then
    func_apply_patch hikey-optee-4.9-new
fi
func_apply_patch x15-master-workarounds
#func_apply_patch x15-master-workarounds-lcr
#func_apply_patch NOUGAT-BOOTTIME-OPTIMIZATIONS-HIKEY
#func_apply_patch NOUGAT-BOOTTIME-OPTIMIZATIONS-X15
#func_apply_patch NOUGAT-BOOTTIME-OPTIMIZATIONS-JUNO

func_apply_patch optee-master-workarounds
func_apply_patch LIUYQ-PATCHSET

#./build.sh
exit
