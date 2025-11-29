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

res=$($com <<< 'declare -n a=b; a=3; echo $b')
[ "$res" = '3' ] || err $LINENO

res=$($com <<< '
bar=one
foo=bar
typeset -n foo
echo ${foo}
echo ${!foo}
')
[ "$res" = 'one
bar' ] || err $LINENO

rm -f $tmp-*
echo $0 >> ./ok
exit

