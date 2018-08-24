#!/bin/bash
function iozone_test_f_r(){
    local f_size=$1
    if [ -z ${f_size} ]; then
        return
    fi
    local rec_size=$2
    if [ -z ${rec_size} ]; then
        return
    fi
    local sync=$3
    if [ -z "${sync}" ]; then
        sync=false
    fi
    fastboot erase userdata
    sleep 2
    fastboot flash userdata nilfs/userdata.img
    sleep 2
    fastboot reboot
    sleep 10
    adb wait-for-usb-device
    sleep 2
    adb shell disablesuspend.sh
    sleep 5
    if ! $sync; then
        adb shell "cd /data && iozone -R -a -s ${f_size} -r ${rec_size} -i 0 -i 1 -i 5 -i 6 -i 7 -b /data/iozone_data.xls" |tee nilfs/tests/${f_size}_${rec_size}.txt
    else
        adb shell "cd /data && iozone -R -a -s ${f_size} -r ${rec_size} -i 0 -i 1 -i 5 -i 6 -i 7 -b /data/iozone_data.xls -+r" |tee nilfs/tests/${f_size}_${rec_size}_sync.txt
    fi
    adb reboot bootloader
}

function iozone_test(){
    local f_size=$1
    if [ -z ${f_size} ]; then
        return
    fi
    local sync=$2
    if [ -z "${sync}" ]; then
        sync=false
    fi
    fastboot erase userdata
    sleep 2
    fastboot flash userdata nilfs/userdata.img
    sleep 2
    fastboot reboot
    sleep 10
    adb wait-for-usb-device
    sleep 2
    adb shell disablesuspend.sh
    sleep 300
    if ! $sync; then
        adb shell "cd /data && iozone -R -a -s ${f_size} -b /data/iozone_data.xls" |tee nilfs/tests/${f_size}.txt
    else
        adb shell "cd /data && iozone -R -a -s ${f_size} -b /data/iozone_data.xls -+r" |tee nilfs/tests/${f_size}_sync.txt
    fi
    adb reboot bootloader
}

adb reboot bootloader
#iozone_test_512M 16384
#iozone_test_512M 8192
#iozone_test_512M 4096
#iozone_test_512M 2048
#iozone_test_512M 1024
#iozone_test_512M 512
#iozone_test_512M 256
#iozone_test_512M 128
#iozone_test_512M 64
if false; then
    iozone_test 64 false
    iozone_test 64 true
    iozone_test 128 false
    iozone_test 128 true
    iozone_test 256 false
    iozone_test 256 true
    iozone_test 512 false
    iozone_test 512 true
    iozone_test 1024 false
    iozone_test 1024 true
    iozone_test 2048 false
    iozone_test 2048 true
    iozone_test 4096 false
    iozone_test 4096 true
    iozone_test 8192 false
    iozone_test 8192 true
    iozone_test 16384 false
    iozone_test 16384 true
    iozone_test 32768 false
    iozone_test 65536 false
fi

for r_size in "4"  "8"  "16"  "32"  "64"  "128"  "256"  "512"  "1024"  "2048"  "4096"  "8192"  "16384"; do
    iozone_test_f_r 32768 ${r_size} true
done

for r_size in "4"  "8"  "16"  "32"  "64"  "128"  "256"  "512"  "1024"  "2048"  "4096"  "8192"  "16384"; do
    iozone_test_f_r 65536 ${r_size} true
done

for r_size in "64"  "128"  "256"  "512"  "1024"  "2048"  "4096"  "8192"  "16384"; do
    iozone_test_f_r 131072 ${r_size} false
    iozone_test_f_r 131072 ${r_size} true
done

for r_size in "64"  "128"  "256"  "512"  "1024"  "2048"  "4096"  "8192"  "16384"; do
    iozone_test_f_r 262144 ${r_size} false
    iozone_test_f_r 262144 ${r_size} true
done
