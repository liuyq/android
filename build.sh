#!/bin/bash -e
ROOT_DIR=$(cd $(dirname $0); pwd)
source ${ROOT_DIR}/scripts-common/helpers

CPUS=$(nproc)
#CPUS=$(($(nproc)/2))

targets="droidcore"
#targets="selinuxtarballs"
#targets="boottarball"
variant="userdebug"

# workaround for boot_fat.uefi.img for error:
# AssertionError: Can only handle FAT with 1 reserved sector
# git clone https://github.com/dosfstools/dosfstools -b v3.0.28
# cd dosfstools && make
export PATH=${ROOT_DIR}/dosfstools:${PATH}

export SHOW_COMMANDS=showcommands
#export ALLOW_MISSING_DEPENDENCIES=true
#export CFG_GP_SOCKETS=n
#export INCLUDE_STLPORT_FOR_MASTER=true
#export INCLUDE_LAVA_HACK_FOR_MASTER=true
#export TARGET_GCC_VERSION_EXP=6.3-linaro
#export USE_CLANG_PLATFORM_BUILD=false
#export WITH_DEXPREOPT=true
#export MALLOC_IMPL=dlmalloc
#export MALLOC_IMPL_MUSL=true
export TARGET_BUILD_JAVA_SUPPORT_LEVEL=platform


function build(){
    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
    export PATH=${JAVA_HOME}/bin:$PATH
    product="${1}"
    if [ -z "${product}" ]; then
        return
    fi
    source build/envsetup.sh
    lunch ${product}-${variant}

    echo "Start to build:" >>time.log
    date +%Y-%m-%d-%H-%M >>time.log
    (time LANG=C make ${targets} -j${CPUS} ) 2>&1 |tee build-${product}.log
    date +%Y-%m-%d-%H-%M >>time.log
}

function build_tools_ddmlib(){
    export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64/
    export PATH=${JAVA_HOME}/bin:$PATH
    export ANDROID_HOME=/backup/soft/adt-bundle-linux/sdk/
    cd tools
    ./gradlew prepareRepo copyGradleProperty
    if [ $? -ne 0 ]; then
        echo "Failed to run:./gradlew prepareRepo copyGradleProperty"
        return
    fi
    ./gradlew assemble
    if [ $? -ne 0 ]; then
        ./gradlew clean assemble
        if [ $? -ne 0 ]; then
            echo "Failed to run:./gradlew clean assemble"
            return
        fi
    fi
    ./gradlew :base:ddmlib:build
    unset JAVA_HOME
}

clean_build() {
    echo -e "\nINFO: Removing entire out dir. . .\n"
    make clobber
}

build_android() {
    echo -e "\nINFO: Build Android tree for $TARGET\n"
    make $@ | tee $LOG_FILE.log
}

build_bootimg() {
    echo -e "\nINFO: Build bootimage for $TARGET\n"
    make bootimage $@ | tee $LOG_FILE.log
}

build_sysimg() {
    echo -e "\nINFO: Build systemimage for $TARGET\n"
    make systemimage $@ | tee $LOG_FILE.log
}

build_usrimg() {
    echo -e "\nINFO: Build userdataimage for $TARGET\n"
    make userdataimage $@ | tee $LOG_FILE.log
}

build_module() {
    echo -e "\nINFO: Build $MODULE for $TARGET\n"
    make $MODULE $@ | tee $LOG_FILE.log
}

build_project() {
    echo -e "\nINFO: Build $PROJECT for $TARGET\n"
    mmm $PROJECT | tee $LOG_FILE.log
}
##########################################################
##########################################################
function build_board_ver(){
    # http://wiki.bash-hackers.org/syntax/pe#use_a_default_value
    local android_board=${1:-hikey}
    local android_ver=${2:-master}
    export_config lcr-reference-${android_board}-${android_ver}
    build ${TARGET_PRODUCT}
}

#export OUT_DIR=/data/android/aosp/out
#SCAN_EXCLUDE_DIRS
#export CFG_TEE_SUPP_LOG_LEVEL=3
KERNEL_VER=4.19
#KERNEL_VER=4.14
export TARGET_KERNEL_USE=${KERNEL_VER}
export TARGET_KERNEL_SOURCE=kernel/linaro/hisilicon-${KERNEL_VER}

rm -fr out/target/product/hikey/obj/kernel
#build_board_ver hikey o
#build_board_ver x15 o
#build_board_ver hikey p
#build_board_ver x15 p
#build_board_ver x15 master
#export TARGET_KERNEL_SOURCE=kernel/linaro/hisilicon-4.4
#make -j"${CPUS}" vts cts

#source build/envsetup.sh
#lunch aosp_arm64-userdebug
#make -j"${CPUS}" cts
#mmm -j"${CPUS}" kernel/tests/net/test
#source build/envsetup.sh
#lunch hikey-userdebug
#make -j"${CPUS}" droidcore
#make -j"${CPUS}" bootimage
build_board_ver hikey master
