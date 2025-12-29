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

res=$($com <<< 'declare -n a=b ; declare -r a ; b=3')
[ $? -eq 1 ] || err $LINENO

res=$($com <<< '
bar=one
typeset -n foo=bar
unset foo
echo ${bar-unset}
echo ${foo-unset}
echo ${!foo}
')
[ "$res" = 'unset
unset
bar' ] || err $LINENO

res=$($com <<< 'declare -n a=b ; declare -p a')
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'declare -n a=b ; unset a ; declare -p a')
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'declare -n a=b ; unset -n a ; declare -p a')
[ $? -eq 1 ] || err $LINENO

res=$($com <<< 'echo ${!aaa}')
[ $? -eq 1 ] || err $LINENO

res=$($com <<< 'echo ${!aaa-unset}')
[ $? -eq 1 ] || err $LINENO
[ "$res" != 'unset' ] || err $LINENO

res=$($com <<< 'b=x; readonly b; declare -n a=b ; unset a')
[ $? -eq 1 ] || err $LINENO

res=$($com <<< 'qux=three; typeset -n ref=; ref=qux; echo $ref')
[ $? -eq 1 ] || err $LINENO

res=$($com <<< 'qux=three; typeset -n ref; ref=qux; echo $ref')
[ "$res" = 'three' ] || err $LINENO

res=$($com <<< 'declare -ai a
a[0]=4
declare -n b='a[0]'
b+=1
declare -p b')
[ "$res" = 'declare -n b="a[0]"' ] || err $LINENO

res=$($com <<< 'declare -ai a
a[0]=4
declare -n b='a[0]'
b+=1
declare -p a')
[ "$res" = 'declare -ai a=([0]="5")' ] || err $LINENO

res=$($com <<< 'declare -ai a; a=(); echo ${a[42]=4+3}')
[ "$res" = '7' ] || err $LINENO

res=$($com <<< 'A=(a); echo ${A[@]@k}')
[ "$res" = '0 a' ] || err $LINENO

res=$($com <<< 'A=(1 2 3); declare "A=(1 2 3)" ; echo ${A[@]}')
[ "$res" = '1 2 3' ] || err $LINENO

res=$($com <<< 'set - a b c; echo $1 $3')
[ "$res" = 'a c' ] || err $LINENO

res=$($com <<< 'arr=(a b c); IFS=+; a=${arr[@]} ; echo "$a"; b=${arr[@]/a/x}; echo "$b"')
[ "$res" = 'a b c
x b c' ] || err $LINENO

res=$($com <<< 'A=( a b c d ) ; N=${#A[@]} ; unset A[N-1] ; echo ${A[@]}')
[ "$res" = 'a b c' ] || err $LINENO

res=$($com <<< 'declare -r c
declare -p c')
[ "$res" = 'declare -r c' ] || err $LINENO

res=$($com <<< 'declare -r c[100]
c[-2]=4
declare -p c')
[ "$res" = 'declare -ar c' ] || err $LINENO

res=$($com <<< 'declare -n b='a[0]' ; a=(1 2 3) ; b=x ; declare -p a')
[ "$res" = 'declare -a a=([0]="x" [1]="2" [2]="3")' ] || err $LINENO

res=$($com <<< 'command declare a=b; echo $a')
[ "$res" = 'b' ] || err $LINENO

res=$($com <<< 'typeset -n ref ; echo ${ref-unset}')
[ "$res" = 'unset' ] || err $LINENO

res=$($com <<< 'typeset -n a='b[1]' ; b=(a B c) ; echo ${a}')
[ "$res" = 'B' ] || err $LINENO

res=$($com <<< 'typeset -n a='b[1]' ; b=(a B c) ; echo $a')
[ "$res" = 'B' ] || err $LINENO


echo 'a() { echo ${FUNCNAME[0]} ; echo ${FUNCNAME[1]} ; }; a' > $tmp-script
res=$($com $tmp-script)
[ "$res" = 'a
main' ] || err $LINENO

echo 'a() { echo ${FUNCNAME[@]} ; }; a' > $tmp-script
res=$($com $tmp-script)
[ "$res" = 'a main' ] || err $LINENO

res=$($com <<< 'f () { caller ; }
f')
[ "$res" = '2 NULL' ] || err $LINENO

res=$($com <<< 'f () { echo ${BASH_LINENO[@]} ; echo ${FUNCNAME[@]}; }
g () { f ; }
g')
[ "$res" = '2 3
f g' ] || err $LINENO

res=$($com <<< 'f () { caller ; }
g () { caller; f ; }
g')
[ "$res" = '3 NULL
2 main' ] || err $LINENO

res=$($com <<< 'f () { caller 0 ; }
g () { f ; }
g')
[ "$res" = '2 g main' ] || err $LINENO

rm -f $tmp-*
echo $0 >> ./ok
exit

