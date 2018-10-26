#!/bin/bash
export BASE=$(cd $(dirname $0);pwd)

source ${BASE}/scripts-common/helpers

sync_init_with_depth(){
    local groups_opt=$(get_manifest_groups)
    while ! repo init --depth=0 ${groups_opt}; do
        sleep 30
    done
}

sync_init_without_depth(){
    local groups_opt=$(get_manifest_groups)
    while ! repo init --depth=0 ${groups_opt}; do
        sleep 30
    done
}

sync(){
    #Syncronize and check out
    while ! repo sync -j ${CPUS} $@; do
        sleep 30
    done
}

sync_init_without_depth
sync "$@"
sync_init_with_depth
