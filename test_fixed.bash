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

res=$($com <<< 'echo " a  b\ " | ( read x y ; echo -"$x"-"$y"- )')
[ "$res" = "-a-b -" ] || err $LINENO

res=$($com <<< 'echo " a  b\ " | ( read x ; echo -"$x"- )')
[ "$res" = "-a  b-" ] || err $LINENO

res=$($com <<< 'echo "a b " | ( read x y z ; echo ${z-z not set} 2>&1 )')
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'echo "A B " | ( read ; echo "[$REPLY]" )')
[ "$res" = "[A B ]" ] || err $LINENO

res=$($com <<< 'echo " A B " | ( read ; echo "[$REPLY]" )')
[ "$res" = "[ A B ]" ] || err $LINENO

res=$($com <<< '(sleep 2 ; echo aaa) | read -t 1 a ; echo $a')
[ "$res" = "" ] || err $LINENO

res=$($com <<< '(sleep 2 ; echo aaa) | read -t 1 a')
[ $? -gt 128 ] || err $LINENO

res=$($com <<< 'echo ${A:aaa} ${A:"aaa"}')
[ $? -eq 0 ] || err $LINENO

res=$($com << 'EOF'
echo ${A:'aaa'}
EOF
)
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'A= ; echo ${A:aaa} ${A:"aaa"}')
[ $? -eq 0 ] || err $LINENO

res=$($com << 'EOF'
A=
echo ${A:'aaa'}
EOF
)
[ $? -eq 1 ] || err $LINENO

res=$($com <<< 'A=abc; echo ${A:13:23:3aa}')
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'A=abc; echo ${A:1:23:3aa}')
[ $? -eq 1 ] || err $LINENO

rm -f $tmp-*
echo $0 >> ./ok
exit

