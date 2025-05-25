#!/bin/bash -xv
# SPDX-FileCopyrightText: 2023 Ryuichi Ueda ryuichiueda@gmail.com
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

[ "$1" == "nobuild" ] || cargo build || err $LINENO
cd "$test_dir"

res=$($com <<< 'cd /; pwd')
[ "$res" = "/" ] || err $LINENO

res=$($com <<< 'cd -- ""' )
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'rm -f /tmp/link; cd /tmp; mkdir -p hoge; ln -s hoge link; cd link; pwd -L; pwd -P')
[ "$res" = "/tmp/link
/tmp/hoge" ] ||
[ "$res" = "/tmp/link
/private/tmp/hoge" ] || err $LINENO

res=$($com <<< 'pwd -a 2>/tmp/rusty_bash; cat /tmp/rusty_bash')
[ "$res" = "sush: pwd: -a: invalid option
pwd: usage: pwd [-LP]" ] || err $LINENO

echo aaaaaaaaaaaaaaaa > /tmp/hoge.txt
res=$($com <<< 'source /tmp/hoge.txt')
[ "$?" = "127" ] || err $LINENO

echo '(' > /tmp/hoge.txt
res=$($com <<< 'source /tmp/hoge.txt')
[ "$?" = "2" ] || err $LINENO

res=$($com <<< 'compgen -W "aaa abc aac" -- aa')
[ "$res" = "aaa
aac" ] || err $LINENO

b=$(compgen -f / | wc -l )
res=$($com <<< 'compgen -f / | wc -l')
[ "$res" = "$b" ] || err $LINENO

b=$(compgen -d /etc | wc -l )
res=$($com <<< 'compgen -d /etc | wc -l')
[ "$res" = "$b" ] || err $LINENO

b=$(compgen -d -- /etc | wc -l )
res=$($com <<< 'compgen -d -- /etc | wc -l')
[ "$res" = "$b" ] || err $LINENO

b=$(cd ; compgen -f . | wc -l )
res=$($com <<< 'cd ; compgen -f . | wc -l')
[ "$res" = "$b" ] || err $LINENO

if [ ! -e ~/tmp/a/b ] ; then 
	res=$($com <<< '
	mkdir -p ~/tmp/a/b
	touch ~/tmp/a/b/c
	compgen -f -X "" -- "~/tmp/a/b/c"
	rm ~/tmp/a/b/c
	rmdir -p ~/tmp/a/b
	rmdir -p ~/tmp/a
	' ) 2> /dev/null
	[ "$res" = "~/tmp/a/b/c" ] || err $LINENO
fi

res=$($com << 'EOF'
toks=(a aa aaa)
compgen -W '"${toks[@]}"'
EOF
)
[ "$res" = "a
aa
aaa" ] || err $LINENO


res=$($com <<< 'compgen -d -- "~/" | wc -l' )
[ "$res" != "0" ] || err $LINENO

res=$($com <<< 'compgen -G "/*" | wc -l' )
[ "$res" -gt 1 ] || err $LINENO

res=$($com <<< 'compgen -f -X "*test*" | grep test')
[ "$?" = "1" ] || err $LINENO

### eval ###

res=$($com <<< 'eval "echo a" b')
[ "$res" = "a b" ] || err $LINENO

res=$($com <<< 'eval -- "A=(a b)"; echo ${A[@]}')
[ "$res" = "a b" ] || err $LINENO

res=$($com <<< 'eval "(" echo abc ")" "|" rev')
[ "$res" = "cba" ] || err $LINENO

res=$($com <<< 'set 1 2 3 ; eval b=(\"\$@\"); echo ${b[0]}')
[ "$res" = "1" ] || err $LINENO

res=$($com <<< 'set 1 2 3 ; eval b=(\"$@\"); echo ${b[0]}')
[ "$res" = "1 2 3" ] || err $LINENO

res=$($com <<< 'set 1 2 3 ; eval -- "a=(\"\$@\")"; echo ${a[0]}')
[ "$res" = "1" ] || err $LINENO

res=$($com <<< 'a=aaa; eval b=\$a; echo $b')
[ "$res" = "aaa" ] || err $LINENO

### unset

res=$($com <<< 'A=aaa ; unset A ; echo $A')
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'A=aaa ; unset -f A ; echo $A')
[ "$res" = "aaa" ] || err $LINENO

res=$($com <<< 'A=aaa ; unset -v A ; echo $A')
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'A () { echo aaa ; } ; unset -v A ; A')
[ "$res" = "aaa" ] || err $LINENO

res=$($com <<< 'A () { echo aaa ; } ; unset -f A ; A')
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'A () { echo aaa ; } ; unset A ; A')
[ "$res" = "" ] || err $LINENO

# builtin command
#
res=$($com <<< 'builtin cd; pwd')
[ "$res" = ~ ] || err $LINENO

# source command

res=$($com <<< 'echo $PS1')
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'case aaa in aaa) return && echo NG ;; esac')
[ "$?" = "2" ] || err $LINENO
[ "$res" = "" ] || err $LINENO

res=$($com << 'EOF'
echo 'echo $1' > /tmp/$$-tmp
source /tmp/$$-tmp aaa
EOF
)
[ "$res" = "aaa" ] || err $LINENO

# export

res=$($com << 'EOF'
export A=1
bash -c 'echo $A'
EOF
)
[ "$res" = "1" ] || err $LINENO

# readonly

res=$($com <<< 'A=1; readonly A ; A=2; echo $A' )
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'readonly x=1; x=2 ; echo $x')
[ "$res" = "" ] || err $LINENO

# break command

$com <<< 'while true ; do break ; done'
#[ "$res" == "" ] || err $LINENO

res=$($com <<< 'while true ; do break ; echo NG ; done')
[ "$res" == "" ] || err $LINENO

res=$($com <<< 'while true ; do while true ; do break ; done ; echo OK ;break ; done; echo OK')
[ "$res" == "OK
OK" ] || err $LINENO

res=$($com <<< 'while true ; do while true ; do break 2 ; done ; echo NG ; done ; echo OK')
[ "$res" == "OK" ] || err $LINENO

res=$($com <<< 'while true ; do while true ; do break 10 ; done ; echo NG ; done ; echo OK')
[ "$res" == "OK" ] || err $LINENO

# continue command

res=$($com <<< 'seq 2 | while read d ; do echo x; continue; echo NG ; done')
[ "$res" == "x
x" ] || err $LINENO

res=$($com <<< 'seq 2 | while read d ; do for a in a b ; do echo x; continue 2 ; done ; echo NG ; done')
[ "$res" == "x
x" ] || err $LINENO

# read

res=$($com <<< 'seq 2 | while read a ; do echo $a ; done ; echo $a ; echo A')
[ "$res" == "1
2

A" ] || err $LINENO

res=$($com <<< 'A=BBB; seq 2 | while read $A ; do echo $BBB ; done')
[ "$res" == "1
2" ] || err $LINENO

res=$($com <<< 'echo あ い う | while read -r a b ; do echo $a ; echo $b ; done')
[ "$res" == "あ
い う" ] || err $LINENO

res=$($com <<< 'echo あ い う | while read a b ; do echo $a ; echo $b ; done')
[ "$res" == "あ
い う" ] || err $LINENO

res=$($com <<< 'echo "aaa\bb" | ( read -r a ; echo $a )' )
[ "$res" = "aaa\bb" ] || err $LINENO

res=$($com <<< 'echo "aaa\bb" | ( read a ; echo $a )' )
[ "$res" = "aaabb" ] || err $LINENO

res=$($com << 'EOF'
echo 'aaa\
bb' | ( read a ; echo $a )
EOF
)
[ "$res" = "aaabb" ] || err $LINENO

res=$($com << 'EOF'
echo 'aaa\
bb' | ( read -r a ; echo $a )
EOF
)
[ "$res" = 'aaa\' ] || err $LINENO

res=$($com <<< 'read -n 4 <<< "  abc def"; echo $REPLY')
[ "$res" = "ab" ] || err $LINENO

res=$($com <<< 'read <<< "abc def"; echo $REPLY')
[ "$res" = "abc def" ] || err $LINENO

res=$($com <<< 'read -n 5 <<< "abc
def"; echo $REPLY')
[ "$res" = "abc" ] || err $LINENO

res=$($com <<< 'read -n 4 foo <<< abcde; echo $foo')
[ "$res" = "abcd" ] || err $LINENO

res=$($com <<< 'read -n 4 foo <<< abc de; echo $foo')
[ "$res" = "abc" ] || err $LINENO

res=$($com <<< 'echo "a:b:" | ( IFS=" :" read x y; echo "($x)($y)" )')
[ "$res" = "(a)(b)" ] || err $LINENO

res=$($com <<< 'echo "a:b::" | ( IFS=" :" read x y; echo "($x)($y)" )')
[ "$res" = "(a)(b::)" ] || err $LINENO

cat << 'EOF' > $tmp-script
echo OK | ( while read line ; do echo $line ; done )
ああああああ！
EOF
res=$($com <<< "source $tmp-script")
[ "$res" = "OK" ] || err $LINENO

# set command

res=$($com <<< 'set -- a b c ; echo $2')
[ "$res" == "b" ] || err $LINENO

res=$($com <<< 'set bob "tom dick harry" joe; set $* ; echo $#')
[ "$res" = "5" ] || err $LINENO

res=$($com <<< 'IFS="" ; set bob "tom dick harry" joe; echo $* ; set $* ; echo $#')
[ "$res" = "bob tom dick harry joe
3" ] || err $LINENO

res=$($com <<< 'IFS="/" ; set bob "tom dick harry" joe; echo $* ; set $* ; echo $#')
[ "$res" = "bob tom dick harry joe
3" ] || err $LINENO

res=$($com <<< 'IFS="/" ; set bob "tom dick harry" joe; echo $* ; set ${*} ; echo $#')
[ "$res" = "bob tom dick harry joe
3" ] || err $LINENO

res=$($com <<< 'IFS="/" ; set bob "tom dick harry" joe; echo $@ ; set $@ ; echo $#')
[ "$res" = "bob tom dick harry joe
3" ] || err $LINENO

res=$($com <<< 'IFS="/" ; set bob "tom dick harry" joe; echo $@ ; set ${@} ; echo $#')
[ "$res" = "bob tom dick harry joe
3" ] || err $LINENO

res=$($com <<< 'IFS=: ; set 1 2 3; b=$* ; set | grep "^b=" ')
[ "$res" = "b=1:2:3" ] || err $LINENO

# $ set | grep ^b
# b=1:2:3
res=$($com <<< 'IFS=: ; set 1 2 3; b=$* ; echo $b ; echo "$b"')
[ "$res" = "1 2 3
1:2:3" ] || err $LINENO

res=$($com <<< 'set a b ; IFS=c ; echo $@ ; echo "$@" ')
[ "$res" = "a b
a b" ] || err $LINENO

res=$($com <<< 'set a b ; IFS="" ; echo $@ ; echo "$@" ')
[ "$res" = "a b
a b" ] || err $LINENO

res=$($com <<< 'set a b ; IFS=c ; echo $* ; echo "$*" ')
[ "$res" = "a b
acb" ] || err $LINENO

res=$($com <<< 'IFS=/ ; set bob "tom dick harry" joe; echo "$*"')
[ "$res" = "bob/tom dick harry/joe" ] || err $LINENO

# shopt command

res=$($com <<< 'shopt -u extglob ; echo @(a)')
[ "$res" == "@(a)" ] || err $LINENO

res=$($com <<< 'shopt -u extglob
echo @(a)')
[ "$?" == "2" ] || err $LINENO
[ "$res" == "" ] || err $LINENO

res=$($com <<< 'shopt -s nullglob ; echo aaaaaa*' )
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'shopt -s nullglob ; echo aaaaaa*; shopt -u nullglob ; echo aaaaaa*' )
[ "$res" = "
aaaaaa*" ] || err $LINENO

res=$($com <<< 'shopt -po noglob' )
[ "$res" = "set +o noglob" ] || err $LINENO

# local

res=$($com -c 'A=1 ; f () { local -a A ; A[1]=123 ; echo ${A[@]} ; } ; f ; echo $A')
[[ "$res" == '123
1' ]] || err $LINENO

res=$($com -c 'A=1 ; f () { local -a A ; A=(2 123) ; echo ${A[@]} ; } ; f ; echo $A')
[[ "$res" == '2 123
1' ]] || err $LINENO

res=$($com -c 'A=1 ; f () { local -A A ; A[aaa]=bbb ; echo ${A[@]} ; } ; f ; echo $A')
[[ "$res" == 'bbb
1' ]] || err $LINENO

res=$($com -c 'A=1 ; f () { local -a A=(2 123) ; echo ${A[@]} ; } ; f ; echo $A')
[[ "$res" == '2 123
1' ]] || err $LINENO

res=$($com -c 'A=1 ; f () { local A=5 ; A=4 ; } ; f ; echo $A')
[[ "$res" == '1' ]] || err $LINENO

res=$($com <<< 'f() { local a=1 ; local "a" && echo "$a" ; } ; f')
[ "$res" = "1" ] || err $LINENO

res=$($com << 'EOF'
f () {
    COMP_LINE='cd ~/G'
    COMP_POINT=6
    local lead=${COMP_LINE:0:COMP_POINT}
    echo $lead
}
f
EOF
)
[ "$res" == "cd ~/G" ] || err $LINENO


res=$($com <<< 'f () { local A=() ; A=(1 2) ; local A;  echo ${A[@]} ; } ; f')
[ "$res" = "1 2" ] || err $LINENO

### declare ###

res=$($com -c 'A=1 ; f () { local A ; declare -r A ; A=123 ; } ; f')
[[ "$?" -eq 1 ]] || err $LINENO

res=$($com -c 'f () { local A ; declare -r A ; A=123 ; } ; f; A=3 ; echo $A')
[[ "$res" -eq 3 ]] || err $LINENO

res=$($com -c 'A=1 ; declare -r A ; f () { local A ; A=123 ; } ; f')
[[ "$?" -eq 1 ]] || err $LINENO

res=$($com -c 'A=1 ; declare -r A ; A=(3 4)')
[[ "$?" -eq 1 ]] || err $LINENO

res=$($com <<< 'declare -i i=1 j=1 ;echo $i $j ')
[ "$res" = "1 1" ] || err $LINENO

res=$($com <<< 'declare -i n; n="1+1" ; echo $n')
[ "$res" = "2" ] || err $LINENO

res=$($com <<< 'declare -i n; echo $(( n ))')
[ "$res" = "0" ] || err $LINENO

res=$($com <<< 'declare -i n; echo $(( (n+1) ))')
[ "$res" = "1" ] || err $LINENO

res=$($com <<< 'declare -i n; echo $(( c=(n+1) ))')
[ "$res" = "1" ] || err $LINENO

res=$($com <<< 'declare -i n; echo $(( c+=(n+1) ))')
[ "$res" = "1" ] || err $LINENO

res=$($com <<< 'declare -i i=1 j=2 k=3
echo $((i += j += k))
echo $i,$j,$k
')
[ "$res" = "6
6,5,3" ] || err $LINENO

res=$($com <<< 'A=(1 2 3) ; declare -r A[1] ; A[0]=aaa ; echo ${A[@]}')
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'unset a ; a=abcde ; declare -a a ; echo ${a[0]}')
[ "$res" = "abcde" ] || err $LINENO

### command ###

res=$($com -c 'command cd /; pwd')
[[ "$res" == / ]] || err $LINENO

res=$($com -c 'command cd /; pwd')
[[ "$res" == / ]] || err $LINENO

### getopts ###

res=$($com -c '
getopts xyz opt -x -y
echo $opt
echo $OPTIND
getopts xyz opt -x -y
echo $opt
echo $OPTIND
')

[[ "$res" == "x
2
y
3" ]] || err $LINENO

res=$($com -c '
getopts x:y:z opt -x hoge -y fuge -z
echo $opt $OPTARG
echo $OPTIND
getopts x:y:z opt -x hoge -y fuge -z
echo $opt $OPTARG
echo $OPTIND
getopts x:y:z opt -x hoge -y fuge -z
echo $opt $OPTARG
echo $OPTIND
')

[[ "$res" == 'x hoge
3
y fuge
5
z
6' ]] || err $LINENO


res=$($com -c '
getopts n: opt -n aho boke fuge
getopts n: opt -n aho boke fuge
getopts n: opt -n aho boke fuge
echo $?
echo $OPTIND
')
[[ "$res" == '1
3' ]] || err $LINENO

res=$($com <<< 'set -- -s --; echo $@
getopts s flag "$@"; res=$?
echo flag:$flag OPTIND:$OPTIND exit:$res
getopts s flag "$@"; res=$?
echo flag:$flag OPTIND:$OPTIND exit:$res
')
[ "$res" = "-s --
flag:s OPTIND:2 exit:0
flag:? OPTIND:3 exit:1" ] || err $LINENO

res=$($com <<< 'getopts :av:U:Rc:C:lF:i:x: _opt -a filedir ; echo $_opt')
[ "$res" = "a" ] || err $LINENO

res=$($com <<< 'getopts :av:U:Rc:C:lF:i:x: _opt -a filedir ; echo $_opt')
[ "$res" = "a" ] || err $LINENO

### this test is not passed only when invoked from this script ###
#res=$($com << 'EOF'
#getopts :alF: _opt -aF : paths a:b
#echo $_opt
#echo $OPTARG
#echo $OPTIND
#getopts :alF: _opt -aF : paths a:b
#echo $_opt
#echo $OPTARG
#echo $OPTIND
#getopts :alF: _opt -aF : paths a:b
#echo $_opt
#echo $OPTARG
#echo $OPTIND
#EOF
#)
#[ "$res" = "a
#
#1
#F
#:
#3
#?
#
#3" ] || err $LINENO

res=$($com <<< '
f()
{
        typeset OPTIND=1
        typeset opt

        while getopts ":abcxyz" opt
        do
                echo opt: "$opt"
                if [[ $opt = y ]]; then f -abc ; fi
        done
}

f -xyz')
[ "$res" = "opt: x
opt: y
opt: a
opt: b
opt: c
opt: z" ] || err $LINENO
[ "$?" -eq 0 ] || err $LINENO


### printf ###

res=$($com <<< 'printf -v a %s bbb &> /dev/null; echo $a')
[ "$res" = "bbb" ] || err $LINENO

res=$($com <<< 'printf -v a %s &> /dev/null; echo $a')
[ "$?" -eq 0 ] || err $LINENO
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'printf -v a bb cc dd &> /dev/null; echo $a')
[ "$res" = "bb" ] || err $LINENO

res=$($com <<< 'printf -v a[3] bb cc dd &> /dev/null; echo ${a[@]}')
[ "$res" = "bb" ] || err $LINENO

res=$($com <<< 'printf -v a[3] bb cc dd &> /dev/null; echo ${a[3]}')
[ "$res" = "bb" ] || err $LINENO

res=$($com <<< 'printf %s abc > /dev/null')
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'printf %s abc &> /dev/null')
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'printf -v REPLY %q /l; echo $REPLY')
[ "$res" = "/l" ] || err $LINENO

res=$($com <<< 'printf "%03x" 123')
[ "$res" = "07b" ] || err $LINENO

res=$($com <<< 'printf "%03X" 123')
[ "$res" = "07B" ] || err $LINENO

res=$($com <<< 'printf "%3X" 123')
[ "$res" = " 7B" ] || err $LINENO

res=$($com <<< 'printf "%-3X" 123')
[ "$res" = "7B " ] || err $LINENO

res=$($com <<< 'printf "%10s" 123')
[ "$res" = "       123" ] || err $LINENO

res=$($com <<< 'printf "%010s" 123')
[ "$res" = "       123" ] || err $LINENO

res=$($com <<< 'printf "%-10s" 123')
[ "$res" = "123       " ] || err $LINENO

res=$($com <<< 'printf "%010d" -123')
[ "$res" = "-000000123" ] || err $LINENO

res=$($com <<< 'printf "%f" -.3')
[ "$res" = "-0.300000" ] || err $LINENO

res=$($com <<< 'printf "%b" "aaa\nbbb"')
[ "$res" = "aaa
bbb" ] || err $LINENO

res=$($com <<< 'printf %q "()\""')
[ "$res" = '\(\)\"' ] || err $LINENO

res=$($com <<< "printf %q '@(|!(!(|)))'")
[ "$res" = '@\(\|\!\(\!\(\|\)\)\)' ] || err $LINENO

res=$($com <<< 'printf -v __git_printf_supports_v %s yes; echo $__git_printf_supports_v' )
[ "$res" = "yes" ] || err $LINENO

res=$($com <<< 'printf -v __git_printf_supports_v -- %s yes; echo $__git_printf_supports_v' )
[ "$res" = "yes" ] || err $LINENO

res=$($com <<< 'printf "== <%s %s> ==\n" a b c' )
[ "$res" = "== <a b> ==
== <c > ==" ] || err $LINENO

res=$($com <<< 'printf "%u\n" 123')
[ "$res" = "123" ] || err $LINENO

res=$($com <<< 'printf "%u\n" -100')
[ "$res" = "18446744073709551516" ] || err $LINENO

res=$($com <<< 'printf "%u\n" -1')
[ "$res" = "18446744073709551615" ] || err $LINENO

res=$($com <<< 'printf "%o\n" 123')
[ "$res" = "173" ] || err $LINENO

res=$($com <<< 'printf "%o\n" -100')
[ "$res" = "1777777777777777777634" ] || err $LINENO

res=$($com <<< 'printf "%i\n" 42')
[ "$res" = "42" ] || err $LINENO

### trap ###
#
res=$($com <<< 'trap "echo hoge" 4') # 4 (SIGILL) is forbidden by signal_hook
[ $? -eq 1 ] || err $LINENO

res=$($com <<< 'trap "echo hoge" QUIT; kill -3 $$; sleep 1')
[ "$res" = "hoge" ] || err $LINENO

res=$($com <<< 'trap "echo hoge" 444444') 
[ $? -eq 1 ] || err $LINENO

res=$($com <<< 'trap "echo hoge" EXIT; echo fuge') 
[ "$res" = "fuge
hoge" ] || err $LINENO

### type ###

res=$($com <<< 'type bash | grep "bash is /"') 
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'type -p bash | grep "^/.*bash"') 
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'type -t for') 
[ "$res" = "keyword" ] || err $LINENO

res=$($com <<< 'type -p printf') 
[ $? -eq 0 ] || err $LINENO
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'type -P printf') 
[ $? -eq 0 ] || err $LINENO
[ "$res" != "" ] || err $LINENO

### let ###

res=$($com <<< 'let a=1; echo $a')
[ "$res" = "1" ] || err $LINENO

res=$($com <<< 'let a=1 b=0; echo $a $b $?')
[ "$res" = "1 0 1" ] || err $LINENO

res=$($com <<< 'let a== b=0; echo $a $b $?')
[ "$res" = "1" ] || err $LINENO

res=$($com <<< 'let "c=$((1+1))"; echo $c $?')
[ "$res" = "2 0" ] || err $LINENO

res=$($com <<< 'let a=1; echo $a')
[ "$res" = "1" ] || err $LINENO

res=$($com <<< 'shopt -o -s posix')
[ "$?" -eq "0" ] || err $LINENO

echo $0 >> ./ok

