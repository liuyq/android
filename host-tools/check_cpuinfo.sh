#!/bin/bash

while true; do
echo ===========================================================
#echo ===========================================================
#echo ==================current freq=============================
#sudo cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_cur_freq
cpuinfo_max_freq=$(sudo cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
cpuinfo_cur_freq=$(sudo cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq)
scaling_cur_freq=$(sudo cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
echo "cpuinfo_max_freq: ${cpuinfo_max_freq}"
echo "cpuinfo_cur_freq: ${cpuinfo_cur_freq}"
echo "scaling_cur_freq: ${scaling_cur_freq}"

#echo ==================max freq=============================
#sudo cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq

#echo ===================temprature ====================
#sudo  cat /sys/class/thermal/thermal_zone*/temp
#sudo  cat /sys/class/thermal/thermal_zone0/temp

sleep 10
done
