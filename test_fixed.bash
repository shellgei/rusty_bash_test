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

res=$(LANG=C $com <<< 'trap 'aaaa' DEBUG
x=1' |& cat | grep "line 2:")
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'shopt -s extdebug; f() { return 2; }; trap f DEBUG; echo hoge')
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'moo() { ls "$1" ; ls "$1" ; } ; moo >(true)')
[ $? -eq 0 ] || err $LINENO

res=$($com <<< '
case a in
[[:al:])	echo bad;;
*)		echo ok;;
esac
')
[ "$res" = "ok" ] || err $LINENO

res=$($com <<< 'case 'a' in [[.a.]]) echo ok;; esac')
[ "$res" = "ok" ] || err $LINENO

res=$($com <<< 'case '-' in [[.hyphen.]]) echo ok;; esac')
[ "$res" = "ok" ] || err $LINENO

res=$($com <<< 'case 'p' in [[.a.]-[.z.]]) echo ok;; esac')
[ "$res" = "ok" ] || err $LINENO

res=$($com <<< 'case '-' in [[.hyphen.]-9]) echo ok;; esac')
[ "$res" = "ok" ] || err $LINENO

res=$($com <<< 'case '8' in [[.hyphen.]-9]) echo ok;; esac')
[ "$res" = "ok" ] || err $LINENO

res=$($com <<< 'shopt -s nocasematch ; A=abc ; echo ${A%C}')
[ "$res" = "ab" ] || err $LINENO

res=$($com <<< '
arrayA=("A" "B" "C")
xx="arrayA[@]"

arrayB=(  "${arrayA[@]}"  )
echo "${#arrayB[@]}---${arrayB[0]}:${arrayB[1]}:${arrayB[2]}"
#arrayB=(  ${!xx}  )
#echo "${#arrayB[@]}---${arrayB[0]}:${arrayB[1]}:${arrayB[2]}"
arrayB=( "${!xx}" )
echo "${#arrayB[@]}---${arrayB[0]}:${arrayB[1]}:${arrayB[2]}"
')
[ "$res" = "3---A:B:C
3---A:B:C" ] || err $LINENO

rm -f $tmp-*
echo $0 >> ./ok
exit

