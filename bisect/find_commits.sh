#!/bin/bash -ex

sha_ok="080d4caf553c"
sha_ng="c7cdbb44e3a4"

f_ng_work=$(mktemp -t bisect-XXX)
f_diff_list=$(mktemp -t files-XXX)
f_commits_list=$(mktemp -t commits-XXX)
git diff ${sha_ng} ${sha_ok} > "${f_ng_work}"
grep 'diff --git' ${f_ng_work} |awk '{print $3}'|sed 's|a/||' > ${f_diff_list}

rm -fr "${f_commits_list}"
while read -r f; do
    echo "$f" >> ${f_commits_list}
    git log --oneline ${sha_ok}..${sha_ng} ${f} |sed 's|^|\t|' >> ${f_commits_list}
done < "${f_diff_list}"

echo "Please check the file of ${f_commits_list}"
