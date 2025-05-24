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

res=$($com <<< "set -a ; _____A=3 ; env | grep _____A")
[ "$res" == "_____A=3" ] || err $LINENO

res=$($com <<< "set -a ; _____A=3 ; unset _____A; env | grep _____A")
[ "$res" == "" ] || err $LINENO

res=$($com <<< "set -a ; _____A+=3 ; env | grep _____A")
[ "$res" == "_____A=3" ] || err $LINENO
unset _____A

res=$($com <<< "set -C ; echo a > $tmp-hoge ; echo b > $tmp-hoge; cat $tmp-hoge")
[ "$res" == "a" ] || err $LINENO

res=$($com <<< 'trap "echo hoge" EXIT; trap')
[ "$res" == "trap -- 'echo hoge' EXIT
hoge" ] || err $LINENO

res=$($com <<< 'trap "echo hoge" SIGHUP; trap')
[ "$res" == "trap -- 'echo hoge' SIGHUP" ] || err $LINENO

res=$($com <<< 'trap "echo hoge" 1; trap')
[ "$res" == "trap -- 'echo hoge' SIGHUP" ] || err $LINENO

res=$($com <<< 'exec hohooh ; echo NG')
[ "$res" == "" ] || err $LINENO

res=$($com <<< 'shopt -s execfail ; exec hohooh ; echo OK')
[ "$res" == "OK" ] || err $LINENO

res=$($com <<< 'set -- -abc ; echo $1')
[ "$res" == "-abc" ] || err $LINENO

res=$($com <<< 'set -- -m ; echo $1')
[ "$res" == "-m" ] || err $LINENO

res=$($com <<< 'set -- a b c ; echo $0')
[ "$res" != "--" ] || err $LINENO

res=$($com -c 'y=$((1 ? 20 : x=2))')
[ $? -eq 1 ] || err $LINENO

res=$($com -c 'set +m; shopt -s lastpipe; echo a | read b; echo $b:$b')
[ "$res" = "a:a" ] || err $LINENO

res=$($com -c 'a=(abc) ; unset a[0]; echo ${a}')
[ "$res" = "" ] || err $LINENO

res=$($com -c 'a=(abc def) ; unset a[0]; echo ${a}')
[ "$res" = "" ] || err $LINENO

res=$($com -c 'a=(def) ; unset a[0]; echo ${a[@]}')
[ "$res" = "" ] || err $LINENO

rm -f $tmp-*
echo $0 >> ./ok
exit

