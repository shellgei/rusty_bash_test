#!/bin/bash -xv
# SPDX-FileCopyrightText: 2023 Ryuichi Ueda ryuichiueda@gmail.com
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

res=$($com <<< 'f () { echo hoge ; } ; declare -f f')
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'f () { echo hoge ; } ; declare -f -- f')
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'a= ; echo ${#a[*]}')
[ "$res" = "1" ] || err $LINENO

res=$($com <<< 'a= ; echo ${#a[@]}')
[ "$res" = "1" ] || err $LINENO

res=$($com <<< 'a=b ; echo ${#a[@]}')
[ "$res" = "1" ] || err $LINENO

res=$($com <<< 'declare a ; echo ${#a[@]}')
[ "$res" = "0" ] || err $LINENO

res=$($com -c 'shopt -q progcomp')
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'shopt -u progcomp ; shopt -q progcomp')
[ $? -eq 1 ] || err $LINENO

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

rm -f $tmp-*
echo $0 >> ./ok
exit

