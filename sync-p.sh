#!/bin/bash -x
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

branch="android-9.0.0_r33"

LOCAL_MANIFEST="git://android-git.linaro.org/platform/manifest.git"
LOCAL_MANIFEST_BRANCH="linaro-p-preview"

main "$@"

#export http_proxy=192.168.0.102:37586
#export https_proxy=192.168.0.102:37586

func_apply_patch P-RLCR-PATCHSET
func_apply_patch hikey-p-workarounds
func_apply_patch hikey-optee-p
if [ -d kernel/linaro/hisilicon-4.14 ]; then
    func_apply_patch hikey-optee-4.14
fi
if [ -d kernel/linaro/hisilicon-4.9 ]; then
    func_apply_patch hikey-optee-4.9-new
fi

func_apply_patch LIUYQ-PATCHSET

#./build.sh
exit
