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

res=$($com << 'FIN'
SQUOTE="'"
val1=$(set | sed -n 's:^SQUOTE=::p')
[ "$val1" != "\'" ] ; echo $?
FIN
)
[ "$res" = '1' ] || err $LINENO

res=$($com <<< 'IFS=; A=("" "") ; echo "<${A[*]}>"')
[ "$res" = '<>' ] || err $LINENO

res=$($com <<< 'IFS=; A=("" "") ; echo "<${A[*]:-a}>"')
[ "$res" = '<a>' ] || err $LINENO

res=$($com <<< 'a[0]= a[1]=; unset a; echo "${a[*]:-y}"')
[ "$res" = 'y' ] || err $LINENO

res=$($com <<< 'a[0]= a[1]=; unset a; echo "${a[@]:-y}"')
[ "$res" = 'y' ] || err $LINENO

res=$($com <<< 'declare -A a=(1 2) ; a=(); declare -p a')
[ "$res" = 'declare -A a=()' ] || err $LINENO

res=$($com <<< 'IFS=+ ; set -- a b c ; b=${@/a/x}; echo "$b"')
[ "$res" = 'x b c' ] || err $LINENO

res=$($com << 'FIN'
a='a b'
declare -A d='($a)'
declare -p d
FIN
)
[ "$res" = 'declare -A d=(["a b"]="" )' ] || err $LINENO

res=$($com <<< 'declare -A a=(1 2 3 4); declare -p a')
[ "$res" = 'declare -A a=([1]="2" [3]="4" )' ] || err $LINENO

res=$($com << 'FIN'
x='a b'
declare -A a=$x
declare -p a
FIN
)
[ "$res" = 'declare -A a=([0]="a b" )' ] || err $LINENO

res=$($com << 'FIN'
value="AbCdE"
declare -a foo
foo=( one two three )
declare -l foo="$value"
declare -p foo
FIN
)
[ "$res" = 'declare -al foo=([0]="abcde" [1]="two" [2]="three")' ] || err $LINENO


res=$($com << 'FIN'
value='[$(echo total 0)]=1 [2]=2]'
declare -a var="($value)"
declare -p var
FIN
)
[ "$res" = 'declare -a var=()' ] || err $LINENO

res=$($com << 'FIN'
declare -a a='(1 2 3)'
echo ${a[0]}
FIN
)
[ "$res" = '1' ] || err $LINENO

res=$($com << 'FIN'
declare a='(1 2 3)'
echo ${a[0]}
FIN
)
[ "$res" = '(1 2 3)' ] || err $LINENO

res=$($com << 'FIN'
b='[0]=bar'
declare -a foo="$b"
declare -p foo
FIN
)
[ "$res" = 'declare -a foo=([0]="[0]=bar")' ] || err $LINENO


res=$($com <<< 'a[1]=a ; [[ -v a ]] || echo ok')
[ "$res" = 'ok' ] || err $LINENO

res=$($com <<< 'a[1]=a ; [[ -v a[1] ]] && echo ok')
[ "$res" = 'ok' ] || err $LINENO

res=$($com <<< 'a[1]=a ; [[ -v a[2] ]] || echo ok')
[ "$res" = 'ok' ] || err $LINENO

res=$($com <<< 'declare -i a="3+1"; declare +i a; a+=a ; echo $a')
[ "$res" = '4a' ] || err $LINENO

res=$($com <<< 'declare -ai -g foo=(1 2 xx 3); echo "${foo[@]}"')
[ "$res" = '1 2 0 3' ] || err $LINENO

res=$($com <<< 'declare -i -a arr=(1+1 2+2 3+3); declare -p arr')
[ "$res" = 'declare -ai arr=([0]="2" [1]="4" [2]="6")' ] || err $LINENO

res=$($com <<< 'x[0]=1 ;x+=( [-1]=foo ); declare -p x')
[ "$res" = 'declare -a x=([0]="foo")' ] || err $LINENO

res=$($com <<< 'a=(1 2 3) ; unset a[-10]; declare -p a')
[ "$res" = 'declare -a a=([0]="1" [1]="2" [2]="3")' ] || err $LINENO

res=$($com <<< 'a=(1 2 3) ; a[-1]=4; declare -p a')
[ "$res" = 'declare -a a=([0]="1" [1]="2" [2]="4")' ] || err $LINENO

res=$($com <<< 'a=(1 2 3) ; echo ${a[-1]}')
[ "$res" = "3" ] || err $LINENO

res=$($com << 'EOF'
func1(){
declare -g variable='function'
declare -g -a array=(function)
}

declare -g variable='main'
declare -g -a array=(main)
func1
echo  ${variable} ${array[@]}
EOF
)
[ "$res" = "function function" ] || err $LINENO

res=$($com <<< 'declare -A array2["foo[bar]"]=bleh; array2["foobar]"]=bleh; array2["foo"]=bbb; echo ${!array2[@]}')
[ "$res" = "foo foo[bar] foobar]" ] || err $LINENO

res=$($com << 'EOF'
declare -A foo
foo=( ['ab]']=bar )
echo ${!foo[@]}
EOF
)
[ "$res" = 'ab]' ] || err $LINENO


rm -f $tmp-*
echo $0 >> ./ok
exit

