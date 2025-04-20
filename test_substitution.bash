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
com="$repo_dir/target/release/sush"
cd "$repo_dir"
tmp=/tmp/$$

[ "$1" == "nobuild" ] || cargo build --release || err $LINENO
cd "$test_dir"

res=$($com <<< 'A=/*; echo $A | grep -q "*"')
[ "$?" == "1" ] || err $LINENO

res=$($com <<< 'A=/*; echo $A | grep -q "etc"')
[ "$?" == "0" ] || err $LINENO

res=$($com <<< 'A=${ }; echo NG')
[ "$ref" != "NG" ] || err $LINENO

res=$($com <<< 'A=${ }')
[ "$?" == 1 ] || err $LINENO

res=$($com <<< 'A=B cd ; echo $A')
[ "$res" == "" ] || err $LINENO

res=$($com <<< 'A=(a b) cd ; echo ${A[0]}')
[ "$res" == "" ] || err $LINENO

res=$($com <<< 'A=aaa ; A+=bbb ; echo $A')
[ "$res" == "aaabbb" ] || err $LINENO

res=$($com <<< 'A=(aaa bbb) ; A+=(ccc ddd) ; echo ${A[@]}')
[ "$res" == "aaa bbb ccc ddd" ] || err $LINENO

res=$($com <<< 'A=BBB; echo $A')
[ "$res" == "BBB" ] || err $LINENO

res=$($com <<< 'A=BBB echo ok')
[ "$res" == "ok" ] || err $LINENO

res=$($com <<< 'A=BBB B= echo ok')
[ "$res" == "ok" ] || err $LINENO

res=$($com <<< 'A=BBB $(); echo $A')
[ "$res" == "BBB" ] || err $LINENO

res=$($com <<< 'A=BBB $(echo); echo $A')
[ "$res" == "BBB" ] || err $LINENO

res=$($com <<< 'A=BBB bash -c "echo \$A"')
[ "$res" == "BBB" ] || err $LINENO

res=$($com <<< 'A=BBB B=CCC bash -c "echo \$A \$B"')
[ "$res" == "BBB CCC" ] || err $LINENO

res=$($com <<< 'A=A$(echo BBB)C; echo $A')
[ "$res" == "ABBBC" ] || err $LINENO

res=$($com <<< 'A={a,b}; echo $A')
[ "$res" == "{a,b}" ] || err $LINENO

res=$($com <<< 'f () { local A=() ; A=(1 2) ; local A;  echo ${A[@]} ; } ; f')
[ "$res" = "1 2" ] || err $LINENO

res=$($com <<< 'A=(
[3]=4 #あいうえお
[4]=5
); echo ${A[3]}')
[ "$res" = "4" ] || err $LINENO

res=$($com <<< 'A=([3]=4); echo ${A[3]}')
[ "$res" = "4" ] || err $LINENO

res=$($com <<< 'declare -A C ; C=(["あ"]=abc) ; echo ${C[あ]}')
[ "$res" = "abc" ] || err $LINENO

res=$($com <<< 'A=(
[3]=4 #あいうえお
[4]=5
); echo ${A[3]}')
[ "$res" = "4" ] || err $LINENO

res=$($com <<< 'A=([3]=4); echo ${A[3]}')
[ "$res" = "4" ] || err $LINENO

res=$($com <<< 'declare -A C ; C=(["あ"]=abc) ; echo ${C[あ]}')
[ "$res" = "abc" ] || err $LINENO


rm -f $tmp-*
echo $0 >> ./ok
exit
