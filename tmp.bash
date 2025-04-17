#!/bin/bash 
# SPDX-FileCopyrightText: 2023 Ryuichi Ueda ryuichiueda@gmail.com
# SPDX-License-Identifier: GPL-3.0-or-later


repo_dir=${2:-~/GIT/rusty_bash}
test_dir="$(cd dirname $0 ; pwd)"
com="$repo_dir/target/release/sush"
cd "$repo_dir"
tmp=/tmp/$$

cat << 'EOF' > $tmp-script
read a
echo @$a
EOF
res=$(bash << EOF
$com $tmp-script
OH
EOF
)
