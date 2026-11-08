#!/bin/bash -e

dir_kernel_src="/home/liuyq/data/android/lkft/kernel/common/mainline"
dir_kernel_src="/home/liuyq/data/android/lkft/common"
kernel_branch="android-mainline"
kernel_branch_current_backup="current_backup"
commit_good="4429151d285e"
commit_bad="0f3be1b18ead"
f_git_log_oneline="${dir_kernel_src}/git-log-oneline.log"
f_bisect="${dir_kernel_src}/git-log-oneline-bisect.log"
number_logs=500

# git log --first-parent -100 --oneline --no-decorate
# git rev-parse b38e72d30c99
##############
cd "${dir_kernel_src}"
res=$(git branch --list ${kernel_branch_current_backup})
[ -n "${res}" ] && git branch -D "${kernel_branch_current_backup}"
git branch "${kernel_branch_current_backup}"
git checkout "${kernel_branch}"
git log --oneline -n${number_logs} > "${f_git_log_oneline}"
cd -

if ! grep -q "^${commit_bad} " "${f_git_log_oneline}"; then
    echo "Note: The bad commit of ${commit_bad} was not found with the \"git log --oneline -n${number_logs}\" "
    echo "Note: Please try with larger log numbers"
    exit 1
fi
if ! grep -q  "^${commit_good} " "${f_git_log_oneline}"; then
    echo "Note: The good commit of ${commit_good} was not found with the \"git log --oneline -n${number_logs}\" "
    echo "Note: Please try with larger log numbers"
    exit 1
fi
found_good=false
found_bad=false
rm -fr "${f_bisect}"
while read line; do
    if ! ${found_bad} && echo "${line}" | grep -q "^${commit_bad} "; then
        found_bad=true
        echo "${line}" >> "${f_bisect}"
    elif echo "${line}" | grep -q "^${commit_good} "; then
        echo "${line}" >> "${f_bisect}"
        found_good=true
        break
    elif ${found_bad} && ! ${found_good}; then
        echo "${line}" >> "${f_bisect}"
        continue
    fi
done < "${f_git_log_oneline}"

number_commits=$(wc -l ${f_bisect}|awk '{print $1-2}')
if [ ${number_commits} -eq 0 ]; then
    echo "There is no commit between the good(${commit_good}) and bad(${commit_bad})"
    echo "Please check the difference between them: git diff ${commit_good} ${commit_bad}"
else
    echo "There are ${number_commits} commits between the good(${commit_good}) and bad(${commit_bad})"
    target_number=$(echo "${number_commits}"|awk '{print $1/2 + 2}')
    target_commit=$(cat -n "${f_bisect}" |egrep "^\s+${target_number}\s+" |awk '{print $2}')

    SRCREV_kernel=${target_commit} ./test.sh
    echo "The images were generated based on commit ${target_commit}"
    grep "^${target_commit} " "${f_bisect}"
    echo "Please deploy and check if that works."
fi
