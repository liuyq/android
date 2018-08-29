#!/bin/bash

while true; do
echo ===========================================================
echo ===========================================================
echo ==================current freq=============================
sudo cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_cur_freq

echo ==================max freq=============================
sudo cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq

echo ===================temprature ====================
sudo  cat /sys/class/thermal/thermal_zone*/temp

sleep 10
done
