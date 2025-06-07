#!/bin/bash -xv
# SPDX-FileCopyrightText: 2024 Ryuichi Ueda ryuichiueda@gmail.com
# SPDX-License-Identifier: GPL-3.0-or-later

err () {
	echo $0 >> ./error
	echo "ERROR!" FILE: $0, LINENO: $1
	exit 1
}


repo_dir=${2:-~/GIT/rusty_bash}
test_dir="$PWD"
com="$repo_dir/target/debug/sush"
cd "$repo_dir"
tmp=/tmp/$$

[ "$1" == "nobuild" ] || cargo build || err $LINENO
cd "$test_dir"

res=$($com <<< 'a=abcdef ; echo ${a: -2:2}')
[ "$res" == 'ef' ] || err $LINENO

res=$($com <<< 'a=abcdef ; echo ${a: -7:2}')
[ "$res" == '' ] || err $LINENO

### RANDOM ###

res=$($com -c '[[ "$RANDOM" -ne "$RANDOM" ]]')
[ "$?" == "0" ] || err $LINENO

res=$($com -c 'RANDOM=a ; echo "$RANDOM"')
[ "$res" != "a" ] || err $LINENO

res=$($com -c 'unset RANDOM; RANDOM=a ; echo "$RANDOM"')
[ "$res" == "a" ] || err $LINENO

res=$($com <<< 'RANDOM=42; v=3 ; (( dice[RANDOM%6+1 + RANDOM%6+1]-=v )) ; echo ${dice[6]}' )
[ "$res" = "-3" ] || err $LINENO

res=$($com <<< 'RANDOM=2 ;echo $RANDOM ; echo $RANDOM')
[ "$res" = "27297
16812" ] || err $LINENO

### TIME ###

res=$($com -c '[[ 0 -eq $SECONDS ]] && sleep 1 && [[ 1 -eq $SECONDS ]]')
[[ "$?" -eq 0 ]] || err $LINENO

res=$($com -c '[[ $(date +%s) -eq $EPOCHSECONDS ]]')
[[ "$?" -eq 0 ]] || err $LINENO

res=$($com -c 'echo $(( $EPOCHREALTIME - $(date +%s) )) | awk -F. "{print \$1}"')
[[ "$res" -eq 0 ]] || err $LINENO

res=$($com -c 'SECONDS=-10 ; sleep 1 ; echo $SECONDS')
[[ "$res" -eq -9 ]] || err $LINENO


### INVALID REF ###

res=$($com <<< 'a= ; echo ${a[@]}')
[ "$?" -eq 0 ] || err $LINENO
[ "$res" = "" ] || err $LINENO


### FUNCNAME ###

res=$($com <<< 'f(){ g () { echo ${FUNCNAME[@]} ;} ; g ;} ; f')
[ "$res" == "g f" ] || err $LINENO

### INDIRECT EXPANSION ###

res=$($com -c 'A=B; B=100; echo ${!A}')
[[ "$res" == 100 ]] || err $LINENO

res=$($com -c 'set a b ; A=1;echo ${!A}')
[[ "$res" == a ]] || err $LINENO

res=$($com -c ' A=@@; echo ${!A}')
[[ "$?" -eq 1 ]] || err $LINENO

res=$($com <<< 'a=(aaa bbb); bbb=eeee ; echo ${!a[1]}')
[ "$res" = "eeee" ] || err $LINENO

res=$($com <<< 'a=(aaa bbb); bbb=eeee ; echo ${!a[1]/ee/bb}')
[ "$res" = "bbee" ] || err $LINENO

res=$($com <<< 'a=(aaa bbb[2]); bbb[2]=eeee ; echo ${!a[1]}')
[ "$res" = "eeee" ] || err $LINENO

res=$($com <<< 'cur=r ;echo ${cur//[[:space:]]/}')
[ "$res" = "r" ] || err $LINENO

res=$($com << 'EOF'
a=(aa bb cc)
echo ${!a[@]}
echo ${!a[*]}
EOF
)
[ "$res" = "0 1 2
0 1 2" ] || err $LINENO

res=$($com << 'EOF'
a=(aa bb cc)
b=("${!a[@]}")
echo ${b[0]}
b=("${!a[*]}")
echo ${b[0]}
EOF
)
[ "$res" = "0
0 1 2" ] || err $LINENO

### POSITION PARAMETER ###

res=$($com <<< 'set a b c; echo a"$@"c')
[ "$res" == "aa b cc" ] || err $LINENO

res=$($com <<< 'set a b c; echo $#')
[ "$res" == "3" ] || err $LINENO

res=$($com <<< 'set a b c; A=( A"$@"C ); echo ${A[0]}')
[ "$res" == "Aa" ] || err $LINENO

res=$($com <<< 'set a b c; A=( A"$@"C ); echo ${A[2]}')
[ "$res" == "cC" ] || err $LINENO

res=$($com <<< 'set a b c; A=( A"$*"C ); echo ${A[0]}')
[ "$res" == "Aa b cC" ] || err $LINENO

res=$($com <<< 'set a b c; A=( A$*C ); echo ${A[1]}')
[ "$res" == "b" ] || err $LINENO

res=$($com <<< 'set a; A=( A"$@"C ); echo ${A[0]}')
[ "$res" == "AaC" ] || err $LINENO

res=$($com <<< 'A=( A"$@"C ); echo ${A[0]}')
[ "$res" == "AC" ] || err $LINENO

res=$($com <<< 'set あ; echo a"$@"c')
[ "$res" == "aあc" ] || err $LINENO

res=$($com <<< 'set あ い; echo a"$@"c')
[ "$res" == "aあ いc" ] || err $LINENO

res=$($com <<< 'echo a"$@"c')
[ "$res" == "ac" ] || err $LINENO

res=$($com <<< 'set a b ; c="$@"; echo $c')
[ "$res" = "a b" ] || err $LINENO

res=$($com <<< 'set a b ; cat <<< $(seq 2)')
[ "$res" = "1
2" ] || err $LINENO

res=$($com <<< 'set a b ; cat <<< "$@"')
[ "$res" = "a b" ] || err $LINENO

res=$($com <<< 'set abc abc; echo ${@/a/A}')
[ "$res" = "Abc Abc" ] || err $LINENO

res=$($com <<< 'set abc abc; echo ${*/a/A}')
[ "$res" = "Abc Abc" ] || err $LINENO

### PARTIAL POSITION PARAMETER ###

res=$($com <<< 'set 1 2 3 4 ; echo ${@:2:2}')
[ "$res" == "2 3" ] || err $LINENO

res=$($com <<< 'set 1 2 3 4 ; echo ${@:1:2}')
[ "$res" == "1 2" ] || err $LINENO

res=$($com <<< 'B=(1 2 3) ; A=("${B[2]}") ; echo ${A[0]}')
[ "$res" == "3" ] || err $LINENO

res=$($com <<< 'set a b ; A=("${@}") ; echo ${A[1]}')
[ "$res" == "b" ] || err $LINENO

res=$($com <<< 'set a b ; A=("${@:1}") ; echo ${A[0]}')
[ "$res" == "a" ] || err $LINENO

res=$($com <<< 'set a b c ; A=("${@:1:1}") ; echo ${A[0]}')
[ "$res" == "a" ] || err $LINENO

res=$($com <<< 'A=(a b) ; echo ${#A[@]}')
[ "$res" -eq 2 ] || err $LINENO

res=$($com <<< 'A=(a b) ; echo "${#A[@]}"')
[ "$res" -eq 2 ] || err $LINENO

res=$($com <<< 'a=(); a=("${a[@]}"); echo ${#a[@]}')
[ "$res" = "0" ] || err $LINENO

res=$($com <<< 'a=(1 2 3); a=("${a[@]:3}"); echo ${#a[@]}')
[ "$res" = "0" ] || err $LINENO

res=$($com <<< 'b=1 ; f () { echo $# ; echo $1 ; } ; f ${b+"$b"}')
[ "$res" = "1
1" ] || err $LINENO

res=$($com <<< 'b= ; f () { echo $# ; echo $1 ; } ; f ${b+"$b"}')
[ "$res" = "1" ] || err $LINENO

res=$($com <<< 'b=() ; f () { echo $# ; echo $1 ; } ; f ${b[@]+"aaa"}')
[ "$res" = "0" ] || err $LINENO

res=$($com <<< 'b=() ; f () { echo $# ; echo $1 ; } ; f ${b[@]+"${b[@]}"}')
[ "$res" = "0" ] || err $LINENO

res=$($com <<< 'a=(a b); set "${a[@]}${a[@]}" ;echo $@ $#' )
[ "$res" = "a ba b 3" ] || err $LINENO

### CASE CONVERSION ###

res=$($com <<< 'a=aba; echo ${a^^[ac]}' )
[ "$res" = "AbA" ] || err $LINENO

res=$($com <<< 'a=あacaba; echo ${a^^[ac]}' )
[ "$res" = "あACAbA" ] || err $LINENO

res=$($com <<< 'a=あacaba; echo ${a^^[cあ]}' )
[ "$res" = "あaCaba" ] || err $LINENO

res=$($com <<< 'a=あAcabA; echo ${a,,[Aあ]}' )
[ "$res" = "あacaba" ] || err $LINENO

res=$($com <<< 'a=あAcabA; echo ${a~~[Aaあ]}' )
[ "$res" = "あacAba" ] || err $LINENO

### IFS ###

res=$($com <<< 'a=" a  b  c "; echo $a; IFS= ; echo $a')
[ "$res" = "a b c
 a  b  c " ] || err $LINENO

res=$($com <<< 'a="@a@b@c@"; IFS=@ ; echo $a@')
[ "$res" = " a b c @" ] || err $LINENO

res=$($com <<< 'a="@a@b@c@"; IFS=@ ; echo $a')
[ "$res" = " a b c" ] || err $LINENO

res=$($com << 'EOF'
IFS='
'
set a '1
2
3'

eval "$1=(\$2)"
echo ${#a[@]}

IFS=
eval "$1=(\$2)"
echo ${#a[@]}
EOF
)
[ "$res" = "3
1" ] || err $LINENO

res=$($com <<< 'a=" a b c "; set 1${a}2 ; echo $#')
[ "$res" = "5" ] || err $LINENO

res=$($com <<< 'IFS=": " ; a=" a b c:"; set 1${a}2 ; echo $#')
[ "$res" = "5" ] || err $LINENO

res=$($com <<< 'IFS=":" ; a=" a b c:"; set 1${a}2 ; echo $#')
[ "$res" = "2" ] || err $LINENO

res=$($com <<< 'IFS=":" ; a=" a b c:"; set "${a}" ; echo $#')
[ "$res" = "1" ] || err $LINENO

res=$($com <<< 'IFS=": "; x=" :"; set x $x; shift; echo "[$#]($1)"')
[ "$res" = "[1]()" ] || err $LINENO

res=$($com <<< 'IFS=": "; x=" a :  : b : "; set x $x; shift; echo "[$#]($1)($2)($3)"')
[ "$res" = "[3](a)()(b)" ] || err $LINENO

res=$($com <<< 'IFS=": "; x=" a : b :  : "; set x $x; shift; echo "[$#]($1)($2)($3)"')
[ "$res" = "[3](a)(b)()" ] || err $LINENO

### position parameter ###

res=$($com -c 'echo ${10}' {0..10})
[ "$res" = '10' ] || err $LINENO

### others ###

res=$($com <<< '
_=aaa
echo $_
echo $_
' )
[ "$res" = "
echo" ] || err $LINENO

res=$($com <<< '__a=x; echo $__a ; echo $__a' )
[ "$res" = "x
x" ] || err $LINENO

### $! ###

res=$($com <<< 'sleep 1 & echo $!')
[ "$res" -gt 0 ] || err $LINENO

echo $0 >> ./ok
