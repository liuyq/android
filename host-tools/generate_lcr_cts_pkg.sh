#!/bin/bash -ex

PUBLISH_TOKEN=''

cur_dir=$(pwd)
parent_dir=$(cd $(dirname $0); pwd)

LINARO_PLANS=""
LINARO_PLANS="${LINARO_PLANS} cts-focused1.xml"
LINARO_PLANS="${LINARO_PLANS} cts-focused2.xml"
LINARO_PLANS="${LINARO_PLANS} cts-media.xml"
LINARO_PLANS="${LINARO_PLANS} cts-media2.xml"
LINARO_PLANS="${LINARO_PLANS} cts-opengl.xml"
LINARO_PLANS="${LINARO_PLANS} cts-part1.xml"
LINARO_PLANS="${LINARO_PLANS} cts-part2.xml"
LINARO_PLANS="${LINARO_PLANS} cts-part3.xml"
LINARO_PLANS="${LINARO_PLANS} cts-part4.xml"
LINARO_PLANS="${LINARO_PLANS} cts-part5.xml"

function prepareCtsDir(){
    local work_dir=$1
    local local_pkg=$2

    cd ${work_dir}
    if [ -f "${local_pkg}" ]; then
        cp -vf ${local_pkg} "${work_dir}/cts.zip"
    fi
    local f_modules_list="${work_dir}/modules.log"
    local f_modules_sort="${work_dir}/modules.sort"
    unzip cts.zip
    ./android-cts/tools/cts-tradefed list modules |tee ${f_modules_list}
    local pos_end=$(grep -n 'Saved log to' ${f_modules_list}  |cut -d: -f1)
    local pos_start=$(grep -n 'Using commandline arguments' ${f_modules_list}  |cut -d: -f1)
    local total_lines=$(wc -l ${f_modules_list})
    local tail_num=$(echo "${total_lines},${pos_start}"|awk -F, '{printf "%d",$1 - $2;}')
    local head_num=$(echo "${pos_start},${pos_end}"|awk -F, '{printf "%d",$2 - $1 - 1;}')
    tail -n ${tail_num} ${f_modules_list} | head -n ${head_num} |sort > ${f_modules_sort}
}

function upload_to_s3(){
    local local_file_path=$1 && shift
    local remote_dir_path=$1 && shift
    # remote url will be https://testdata.linaro.org/${remote_dir_path}/$(basename $(local_file_path))
    export PUBLISH_TOKEN
    wget https://git.linaro.org/ci/publishing-api.git/plain/linaro-cp.py -O linaro-cp.py
    python linaro-cp.py ${local_file_path} ${remote_dir_path} --server=https://testdata.linaro.org/
    rm -fr linaro-cp.py
}

function upload_build_info_to_s3(){
    local remote_dir_path=$1
    local build_info_path="/tmp/BUILD-INFO.txt"
    local build_info="Format-Version: 0.5\n\nFiles-Pattern: *\nLicense-Type: open\n"
    echo -e ${build_info} >${build_info_path}

    upload_to_s3 ${build_info_path} ${remote_dir_path}
    rm -fr ${build_info_path}
}

function generateLCRCtsPackage(){
    local local_ref_pkg=$1 && shift
    local local_src_pkg=$1 && shift
    local local_dest_pkg=$1 && shift
    local local_dir=$(date +%y.%m)

    if which java >/dev/null; then
        local working_dir=$(mktemp -d -p /tmp/ -d CTS-XXX)
        mkdir ${working_dir}/ref ${working_dir}/src

        ## https://developer.android.com/studio/releases/platform-tools
        ## https://dl.google.com/android/repository/platform-tools_r28.0.0-linux.zip
        ## https://developer.android.com/studio/releases/build-tools
        build_tools_ver="28.0.2"
        wget https://dl.google.com/android/repository/build-tools_r${build_tools_ver}-linux.zip -O ${working_dir}/build-tools_r${build_tools_ver}-linux.zip
        pushd ${working_dir} && unzip ${working_dir}/build-tools_r${build_tools_ver}-linux.zip && popd
        #export PATH=${PATH}:${working_dir}/android-8.1.0
        export PATH=${PATH}:${working_dir}/android-9

        prepareCtsDir "${working_dir}/ref" ${local_ref_pkg}
        prepareCtsDir "${working_dir}/src" "${local_src_pkg}"

        cp ${working_dir}/src/android-cts/testcases/egl-master.txt ${working_dir}/src/egl-master.txt && \
        cp ${working_dir}/src/android-cts/tools/cts-tradefed.jar ${working_dir}/src/cts-tradefed.jar && \
        rm -fr ${working_dir}/src/android-cts

        mkdir -p ${working_dir}/src/android-cts/testcases/ ${working_dir}/src/android-cts/tools/config
        sed -i '/dEQP-EGL.functional.sharing.gles2.multithread.random.images.copyteximage2d/d' ${working_dir}/src/egl-master.txt > ${working_dir}/src/android-cts/testcases/egl-master.txt

        cd ${working_dir}/ref/android-cts/tools/ && rm -fr config && jar -xf cts-tradefed.jar
        for sub_plan in ${LINARO_PLANS}; do
            mv config/${sub_plan} ${working_dir}/src/android-cts/tools/config/${sub_plan}
        done
        cd ${working_dir}

        if ! diff ${working_dir}/ref/modules.sort ${working_dir}/src/modules.sort > ${working_dir}/diff.txt; then
            grep '^>' ${working_dir}/diff.txt|awk '{print $2}' > ${working_dir}/modules-src-only.txt
            grep '^<' ${working_dir}/diff.txt|awk '{print $2}' > ${working_dir}/modules-ref-only.txt
            cd ${working_dir}/src/android-cts//tools/config

            ## remove modules in old version
            while read -r module_name; do
                for config_f in `ls cts-*.xml`; do
                    sed -i "/value=\"${module_name}\"/d" ${config_f}
                    sed -i "/value=\"${module_name}\ /d" ${config_f}
                done
            done < ${working_dir}/modules-ref-only.txt

            ## add modules in new version to cts-part5.xml
            while read -r module_name; do
                new_module_line="    <option name=\"compatibility:include-filter\" value=\"${module_name}\" />"
                sed "/<\/configuration>/i ${new_module_line}" cts-part5.xml
            done < ${working_dir}/modules-src-only.txt
        fi

        cp ${working_dir}/src/cts-tradefed.jar ${working_dir}/src/android-cts/tools && cd ${working_dir}/src/android-cts/tools && jar -uvf cts-tradefed.jar config/

        cd ${working_dir}/src/ && \
            zip -ru cts.zip android-cts && \
            mv -v cts.zip ${local_dest_pkg} \

    #       &&  upload_to_s3 "${local_dest_pkg}" "cts/${local_dir}"
    else
        echo "No java command is found, please generate the linaro cts package manually"
    fi
}

ref_pkg="${cur_dir}/android-cts-9.0_r4-linux_x86-arm-linaro.zip"
src_pkg="${cur_dir}/android-cts-9.0_r5-linux_x86-arm.zip"
dest_pkg="${cur_dir}/android-cts-9.0_r5-linux_x86-arm-linaro.zip"

generateLCRCtsPackage ${ref_pkg} ${src_pkg} ${dest_pkg}
#upload_to_s3 "${dest_pkg}" "cts/18.09"
#upload_build_info_to_s3 "cts/18.09"


#upload_to_s3 "${dest_pkg}" "cts/aosp-master"
#upload_build_info_to_s3 "cts/aosp-master"
