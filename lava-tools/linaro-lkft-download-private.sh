#!/bin/bash -ex

## ${0} config_url output_path

#config_user="yongqin.liu@linaro.org"
#config_password="Liuyq0307"
config_name="lkft-eap-db845c-android14-android14-6.1-gki"
config_local_path=$(mktemp -u "/tmp/${config_name}-XXX")
config_target_url="https://${config_domain}/android-internal/android-build-configs.git/plain/lkft/${config_name}?h=lkft"

function source_lava_secrets(){
    lava_test_dir="$(find /lava-* -maxdepth 0 -type d | grep -E '^/lava-[0-9]+' 2>/dev/null | sort | tail -1)"
    if test -f "${lava_test_dir}/secrets" && grep -q "ARTIFACTORIAL_TOKEN" "${lava_test_dir}/secrets"; then
        # shellcheck disable=SC1090
        . "${lava_test_dir}/secrets"
    fi
}
function init_netrc(){
    local f_netrc="${1}"

    source_lava_secrets
    config_domain="${DEV_PRIVATE_DOMAIN:-dev-private-git.linaro.org}"
    if [ -n "${DEV_PRIVATE_USER}" ] && [ -n "${DEV_PRIVATE_PASSWORD}" ]; then
        echo "Set ${f_netrc} with the defined DEV_PRIVATE_USER and DEV_PRIVATE_PASSWORD secrets"
        set +x
        echo "machine ${config_domain} login ${DEV_PRIVATE_USER} password ${DEV_PRIVATE_PASSWORD}" >"${f_netrc}"
        set -x
    else
        echo "No DEV_PRIVATE_USER or DEV_PRIVATE_PASSWORD defined to generate the netrc file"
    fi
}

function download_with_curl(){
    local target_url="${1}"
    local local_path="${2}"
    local f_netrc=$(mktemp -u "/tmp/dev-private-git-XXX.netrc")
    init_netrc "${f_netrc}"
    if [ ! -f "${f_netrc}" ] || [ ! -s "{f_netrc}" ]; then
        curl "${target_url}" > "${local_path}"
    else
        curl --netrc-file "${f_netrc}" "${target_url}" > "${local_path}"
    fi

    # clean the netrc file after used
    rm -f "${f_netrc}"
}
download_with_curl "${config_target_url}" "${config_local_path}"
