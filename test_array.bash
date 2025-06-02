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

res=$($com <<< 'A=( a b ); echo ${A[1]}')
[ "$res" == "b" ] || err $LINENO

res=$($com <<< 'A=( a b ); echo ${A[5 -4 ]}')
[ "$res" == "b" ] || err $LINENO

res=$($com <<< 'A=( a b ); B=1; echo ${A[$B]}')
[ "$res" == "b" ] || err $LINENO

res=$($com <<< 'A=( a b ); echo ${A[@]}')
[ "$res" == "a b" ] || err $LINENO

res=$($com <<< 'A=( a b ); A[0]=c ; echo ${A[@]}')
[ "$res" == "c b" ] || err $LINENO

res=$($com <<< 'A=( a b ); A[0]=( 1 2 )')
[ "$?" == 1 ] || err $LINENO

res=$($com <<< 'A=( a b ); A[]=1')
[ "$?" == 1 ] || err $LINENO

res=$($com <<< 'test=(first & second)')
[ "$?" -eq "1" ] || err $LINENO

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


### ASSOCIATED ARRAY ###

res=$($com <<< 'declare -A A; A[aaa]=bbb; echo ${A[aaa]}')
[ "$res" == "bbb" ] || err $LINENO

res=$($com <<< 'declare -A A; A[aaa]=bbb ;A[ccc]=ddd ; echo ${A[@]}')
[ "$res" == "ddd bbb" -o "$res" == "bbb ddd" ] || err $LINENO

res=$($com <<< 'B=ccc; declare -A A; A[aaa]=bbb ;A[ccc]=ddd ; echo ${A[$B]}')
[ "$res" == "ddd" ] || err $LINENO

res=$($com <<< 'declare -a arr ; arr=bbb ; echo ${arr[0]}')
[ "$res" == "bbb" ] || err $LINENO

res=$($com <<< 'declare -A a; echo ${a[aaa]}')
[ "$?" = "0" ] || err $LINENO
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'declare -iA a ; a["hoge"]=1+1; echo ${a["hoge"]}')
[ "$res" == '2' ] || err $LINENO

res=$($com <<< 'a=1; declare -A a; declare -A | grep " a="')
[ "$res" == 'declare -A a=([0]="1" )' ] || err $LINENO

rm -f $tmp-*
echo $0 >> ./ok
exit

