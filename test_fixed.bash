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

res=$($com <<< "echo 123 | tee >(rev)")
[ "$res" = '123
321' ] || err $LINENO

### TODO: not fixed ###
#res=$($com <<< "echo 123 | tee >(rev) | rev --")
#[ "$res" = '321
#123' ] || err $LINENO

res=$($com << 'EOF'
rkey=']'
declare -A A
A[$rkey]=rbracket
unset A[$rkey]
declare -p A
EOF
)
[ "$res" = 'declare -A A=()' ] || err $LINENO

res=$($com <<< "declare -A assoc=( [one]=one ) ; assoc+=( [one]+=more ); declare -p assoc")
[ "$res" = 'declare -A assoc=([one]="onemore" )' ] || err $LINENO

res=$($com <<< "declare -A a; a[hoe hoe]=b ; declare -p a")
[ "$res" = 'declare -A a=(["hoe hoe"]="b" )' ] || err $LINENO

res=$($com <<< "declare -A chaff; declare -i chaff; chaff=( [zero]=1+4 [one]=3+7 four ); declare -A | grep chaff")
[ "$res" = 'declare -Ai chaff=([one]="10" [zero]="5" )' ] || err $LINENO

res=$($com <<< "declare -a e[10]=(test); declare -p e")
[ "$res" = '' ] || err $LINENO

res=$($com <<< "declare -a e[10]=test; declare -p e")
[ "$res" = 'declare -a e=([10]="test")' ] || err $LINENO

res=$($com <<< "declare -a e[10]='(test)'; declare -p e")
[ "$res" = 'declare -a e=([0]="test")' ] || err $LINENO

res=$($com <<< 'declare -A A ; declare -u A ; echo ${A[hoge]=foo}; echo ${A[hoge]}')
[ "$res" = "FOO
FOO" ] || err $LINENO

res=$($com <<< 'declare -u a; a=abc; echo $a')
[ "$res" = "ABC" ] || err $LINENO

res=$($com <<< 'a=abc ; echo "${a@k}"')
[ "$res" = "'abc'" ] || err $LINENO

res=$($com <<< 'set a b ; echo "${@@k}"')
[ "$res" = "'a' 'b'" ] || err $LINENO

res=$($com <<< 'A=(a b) ; echo "${A[@]@k}"')
[ "$res" = "0 a 1 b" ] || err $LINENO

res=$($com <<< 'A=(a b) ; echo "${A[@]@K}"')
[ "$res" = '0 "a" 1 "b"' ] || err $LINENO

res=$($com <<< 'A=(a b) ; echo "${A[@]@Q}"')
[ "$res" = "'a' 'b'" ] || err $LINENO

if [ "$(uname)" = Linux ] ; then
    res=$(diff <($com <<< 'ulimit -a') <(bash <<< 'ulimit -a'))
    [ $? -eq 0 ] || err $LINENO
    [ "$res" = '' ] || err $LINENO
    
    res=$(diff <($com <<< 'ulimit -Ha') <(bash <<< 'ulimit -Ha'))
    [ $? -eq 0 ] || err $LINENO
    [ "$res" = '' ] || err $LINENO
fi

rm -f $tmp-*
echo $0 >> ./ok
exit

