#!/bin/bash -ex

mkdir -p fengshen-new
for f in fengshen-org/*.mp3; do
   f_name_old=$(basename "$f")
   f_name_new=$(echo "${f_name_old}"|tr -d ' ')
   ffmpeg -i "fengshen-org/${f_name_old}" -vn -acodec copy -ss 00:00:22 "fengshen-new/${f_name_new}"
done

# crop audio
# ffmpeg -i 111.mp3 -vn -acodec copy -t 00:01:52 222.mp3

# reduce video size with ffmpeg
# ffmpeg -i VID_20200814_104245-new.mp4 -b 4420k -s 480x270 VID_20200814_104245-new-480.mp4
