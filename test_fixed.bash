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

res=$($com <<< '
f () { echo aho ; }
g () { local f=3 ; echo $f ; f ; unset f; echo $f ; f ; }
g
')
[ "$res" = "3
aho

aho" ] || err $LINENO

res=$($com <<< ' typeset -i ivar; typeset -n iref=ivar; (( iref=17 )); echo $iref' )
[ "$res" = "17" ] || err $LINENO

res=$($com <<< 'a=b;  typeset -n c=a; c=2; echo $a; typeset +n c; c=3; echo $a' )
[ "$res" = "2
2" ] || err $LINENO

res=$($com <<< 'bar=4; typeset -n foo=bar; typeset -n one=foo; echo one:$one foo:$foo bar:$bar')
[ "$res" = "one:4 foo:4 bar:4" ] || err $LINENO

res=$($com <<< 'bar=4; typeset -n foo='bar[0]'; echo foo:$foo bar:$bar')
[ "$res" = "foo:4 bar:4" ] || err $LINENO

res=$($com <<< 'bar=4; typeset -n foo='bar[hoge]'; typeset -n one=foo; echo one:$one foo:$foo bar:$bar')
[ "$res" = "one:4 foo:4 bar:4" ] || err $LINENO

res=$($com <<< 'bar=4; typeset -n foo='bar[0]'; typeset -n one=foo; echo one:$one foo:$foo bar:$bar')
[ "$res" = "one:4 foo:4 bar:4" ] || err $LINENO

res=$($com <<< 'typeset -n b=a ; a=3 ; echo $a')
[ "$res" = "3" ] || err $LINENO

res=$($com <<< 'typeset -n b=a ; a=3 ; typeset -n b=a ; echo $a')
[ "$res" = "3" ] || err $LINENO

res=$($com <<< '
v1=1
v2=2

typeset -n v=v1
for v in v1 v2; do
        declare -p v v1 v2
        echo "${!v}: $v"
done
declare -p v
')
[ "$res" = 'declare -n v="v1"
declare -- v1="1"
declare -- v2="2"
v1: 1
declare -n v="v2"
declare -- v1="1"
declare -- v2="2"
v2: 2
declare -n v="v2"' ] || err $LINENO

res=$($com <<< '
x=(X)
y=(Y)
typeset -n x=y
echo $x -- $?
')
[ "$res" = "X -- 1" ] || err $LINENO

res=$($com <<< 'f () { local a=bbb ; unset a ; } ; a=ccc ; f ; echo $a')
[ "$res" = "ccc" ] || err $LINENO

res=$($com <<< 'set -a ; aaa=bbb ; env | grep ^aaa')
[ "$res" = "aaa=bbb" ] || err $LINENO

rm -f $tmp-*
echo $0 >> ./ok
exit

