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

#res=$($com <<< 'let a=(5 + 3) b=(4 + 7); echo $a $b')
#[ "$res" == '8 11' ] || err $LINENO

res=$($com <<< 'f () { typeset IFS=: ; echo $1 ; } ; f a:b')
[ "$res" == 'a b' ] || err $LINENO

res=$($com <<< 'a=abcdef ; echo ${a: -2:2}')
[ "$res" == 'ef' ] || err $LINENO

res=$($com <<< 'a=abcdef ; echo ${a: -7:2}')
[ "$res" == '' ] || err $LINENO

res=$($com <<< 'a=(1 2 3) ; echo ${a[@]:-2:2}')
[ "$res" == '1 2 3' ] || err $LINENO

res=$($com <<< 'a=(1 2 3) ; echo ${a[@]: -2:2}')
[ "$res" == '2 3' ] || err $LINENO

res=$($com <<< 'a=(1 2 3) ; echo ${a[@]: -5:2}')
[ "$res" == '' ] || err $LINENO

res=$($com <<< 'x=([1]="" [2]="" [3]=a [5]=b) ; echo "${x[@]:3:2}"')
[ "$res" == "a b" ] || err $LINENO

res=$($com <<< '
declare -i -a iarray
iarray=( 2+4 1+6 7+2 )
echo ${iarray[@]}')
[ "$res" == "6 7 9" ] || err $LINENO

res=$($com <<< 'x=(1 2) ; IFS=""; echo "${x[*]}"')
[ "$res" == "12" ] || err $LINENO

res=$($com <<< 'echo efgh | ( read x[1] ; echo ${x[1]} )')
[ "$res" == 'efgh' ] || err $LINENO

res=$($com <<< 'a=([]=a [1]=b) ; echo ${a[1]}')
[ "$res" == 'b' ] || err $LINENO

res=$($com <<< 'a=(1 2 3) ; unset a[*]; echo ${a[@]}')
[ "$res" == '' ] || err $LINENO

res=$($com <<< 'a=(1 2 3) ; unset a[@]; echo ${a[@]}')
[ "$res" == '' ] || err $LINENO

res=$($com <<< 'a=(1 2 3) ; echo ${a[    ]}')
[ "$res" == '1' ] || err $LINENO

res=$($com <<< 'd=([5]=aaa); echo "${d[@]}"')
[ "$res" == 'aaa' ] || err $LINENO

res=$($com << 'EOF'
d=([5]=aaa)
declare -a f='("${d[@]}")'
declare -a | grep ' f='
EOF
)
[ "$res" == 'declare -a f=([0]="aaa")' ] || err $LINENO

res=$($com <<< 'declare -ai a ; a[0]=1+1; echo ${a[0]}')
[ "$res" == '2' ] || err $LINENO

res=$($com <<< 'a[0]=A; a[1]=B ; unset a[0]; echo ${#a[@]}')
[ "$res" == '1' ] || err $LINENO

res=$($com <<< 'a=1; declare -A a; declare -A | grep " a="')
[ "$res" == 'declare -A a=([0]="1" )' ] || err $LINENO

res=$($com <<< 'readonly a=bbb; echo $a')
[ "$res" == "bbb" ] || err $LINENO

res=$($com <<< 'declare -r a=bbb; echo $a')
[ "$res" == "" ] || err $LINENO

res=$($com <<< 'declare a[10]=bbb; echo ${a[@]}')
[ "$res" == "bbb" ] || err $LINENO

res=$($com <<< 'declare -a a[10]=bbb; echo ${a[@]}')
[ "$res" == "bbb" ] || err $LINENO

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

