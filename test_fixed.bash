#!/bin/bash -xv
# SPDX-FileCopyrightText: 2025 Ryuichi Ueda ryuichiueda@gmail.com
# SPDX-License-Identifier: GPL-3.0-or-later

err () {
	echo $0 >> ./error
	echo "ERROR!" FILE: $0, LINENO: $1
	rm -f $tmp-*
	exit 1
}

repo_dir=${2:-~/GIT/rusty_bash}
test_dir="$PWD"
com="$repo_dir/target/debug/sush"
cd "$repo_dir"
tmp=/tmp/$$

[ "$1" == "nobuild" ] || cargo build || err $LINENO
cd "$test_dir"


res=$($com << 'EOF'
echo "${foo-'}'}"
EOF
)
[ "$res" = "'}'" ] || err $LINENO

res=$($com << 'EOF'
set -o posix
echo "${foo-'}'}"
EOF
)
[ "$res" = "''}" ] || err $LINENO

res=$($com <<< 'printf -v ret %q ""; echo "$ret"')
[ "$res" = "''" ] || err $LINENO

res=$($com <<< 'f () { local a=bbb ; unset a ; } ; a=ccc ; f ; echo $a')
[ "$res" = "ccc" ] || err $LINENO

rm -f $tmp-*
echo $0 >> ./ok
exit

