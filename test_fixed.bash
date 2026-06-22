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

res=$($com <<< 'for invalid-name in a b c; do echo error; done')
[ $? -eq 1 ] || err $LINENO

res=$($com <<< 'for i do ii aaa ; done')
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'select a in b c d ; do echo $a ; done <<< 2')
[ "$res" = "c" ] || err $LINENO

res=$($com <<< 'for (( i = 0; i < 2; i++ )) { echo $i ; }')
[ $? -eq 0 ] || err $LINENO
[ "$res" = "0
1" ] || err $LINENO

res=$($com <<< '
a[b[c]d]=e' 2>&1 | tr -dc 0-9 )
[ "$res" = "2" ] || err $LINENO

res=$($com <<< '
let "rv = 7 + (43 * 6"' 2>&1 | tr -dc 0-3 )
[ "$res" = "2" ] || err $LINENO

res=$($com <<< 'declare -i i
i=0#4' 2>&1 | tr -dc 1-3 )
[ "$res" = "2" ] || err $LINENO

res=$($com <<< '
until (( x == 4 ))
do
        echo $x
        x=4
done
')
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'fuあnc() { echo aho ; }; fuあnc')
[ "$res" = "aho" ] || err $LINENO

res=$($com <<< 'fu%nc() { echo aho ; }; fu%nc')
[ "$res" = "aho" ] || err $LINENO

res=$($com <<< 'for ((i = 0; ;i++ )) ; do echo $i ; exit 0; done')
[ "$res" = "0" ] || err $LINENO

#res=$(bash <<< 'a () { echo a | rev | rev & } ; declare -f a')
#[ "$res" = 'a ()
#{
#    echo a | rev | rev &
#}
#' ] || err $LINENO

res=$($com <<< '
f1()
{
	local zz
	zz=abcde
	unset zz
	zz=defghi
}

zz=ZZ
f1
echo $zz
')
[ "$res" = "ZZ" ] || err $LINENO

res=$($com <<< 'cat <(exit 3) > /dev/null ; wait $!; echo $?')
[ "$res" = "3" ] || err $LINENO

rm -f $tmp-*
echo $0 >> ./ok
exit

