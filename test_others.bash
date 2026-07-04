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

### SIMPLE COMMAND TEST ###

res=$($com <<< 'echo hoge')
[ "$res" = "hoge" ] || err $LINENO

res=$($com <<< ' echo hoge')
[ "$res" = "hoge" ] || err $LINENO

res=$($com <<< '	echo hoge')
[ "$res" = "hoge" ] || err $LINENO

res=$($com <<< 'echo hoge;')
[ "$res" = "hoge" ] || err $LINENO

res=$($com <<< '! eeee' )
[ "$?" = "0" ] || err $LINENO

res=$($com <<< '! echo' )
[ "$?" = "1" ] || err $LINENO

res=$($com <<< '! cd' )
[ "$?" = "1" ] || err $LINENO

res=$($com <<< '!' )
[ "$?" = "1" ] || err $LINENO

### PARAMETER TEST ###
#
res=$($com <<< '_AAA=3 ; echo $_AAA' )
[ "$res" = "3" ] || err $LINENO

res=$($com <<< 'echo ${A:-abc}' )
[ "$res" = "abc" ] || err $LINENO

res=$($com <<< 'echo ${A:-abc}; echo $A' )
[ "$res" = "abc" ] || err $LINENO

res=$($com <<< 'echo ${A:=abc}; echo $A' )
[ "$res" = "abc
abc" ] || err $LINENO

res=$($com <<< 'echo ${A:="aaa
bbb"}
echo "$A"' )
[ "$res" = "aaa bbb
aaa
bbb" ] || err $LINENO

res=$($com <<< 'echo ${A:?error}' )
[ "$?" = "1" ] || err $LINENO
[ "$res" = "" ] || err $LINENO

res=$($com <<< '(echo ${A:?eRRor}) |& cat' )
echo "$res" | grep -q eRRor || err $LINENO

res=$($com <<< 'A=123; echo ${A:?eRRor}' )
[ "$res" = "123" ] || err $LINENO

res=$($com <<< 'A= ; echo ${A:+set}' )
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'A=aaa ; echo ${A:+set}' )
[ "$res" = "set" ] || err $LINENO

res=$($com <<< 'A=aaa ; echo ${A:+"set
ok"}' )
[ "$res" = "set
ok" ] || err $LINENO

res=$($com <<< 'echo ${A-abc}' )
[ "$res" = "abc" ] || err $LINENO

res=$($com <<< 'A=a ; echo ${A-abc}' )
[ "$res" = "a" ] || err $LINENO

res=$($com <<< 'echo ${A+abc}' )
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'A=a ; echo ${A+abc}' )
[ "$res" = "abc" ] || err $LINENO

res=$($com <<< 'A=aaa ; echo ${A- - - - -}' )
[ "$res" = "aaa" ] || err $LINENO

res=$($com <<< 'A=aaa ; echo ${A+- - - - bbb}' )
[ "$res" = "- - - - bbb" ] || err $LINENO

res=$($com <<< 'A= ; echo ${A+- - - - bbb}' )
[ "$res" = "- - - - bbb" ] || err $LINENO

res=$($com <<< 'echo ${A:-   abc}' )
[ "$res" = "abc" ] || err $LINENO

res=$($com <<< 'echo ${A:-abc def}' )
[ "$res" = "abc def" ] || err $LINENO

res=$($com <<< 'echo ${A:-abc   def}' )
[ "$res" = "abc def" ] || err $LINENO

res=$($com <<< 'B=あ ; echo ${A:-$B def}' )
[ "$res" = "あ def" ] || err $LINENO

res=$($com <<< 'B=あ ; echo ${A:-$B
def}' )
[ "$res" = "あ def" ] || err $LINENO

res=$($com <<< 'B=あ ; echo ${A:-"$B
def"}' )
[ "$res" = "あ
def" ] || err $LINENO

res=$($com <<< 'A=aaa; B= ; echo ${B+$A}' )
[ "$res" = "aaa" ] || err $LINENO

res=$($com <<< 'A=aaa; echo ${B+$A}' )
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'A=aaa; B=b ; echo ${B+$A}' )
[ "$res" = "aaa" ] || err $LINENO

res=$($com <<< 'a=(a b) ; echo ${a+"${a[@]}"}')
[ "$res" = "a b" ] || err $LINENO


res=$($com << 'EOF'
_cur=a
b=(${_cur:+-- "$_cur"})
echo ${b[0]}
echo ${b[1]}
EOF
)
[ "$res" = "--
a" ] || err $LINENO

res=$($com <<< 'a=A ; echo ${a:-B}' )
[ "$res" = "A" ] || err $LINENO

res=$($com <<< 'set a ; b=${1-" "}; echo $b' )
[ "$res" = "a" ] || err $LINENO

res=$($com << 'EOF'
echo "${dbg-'"'hey}"
EOF
)
[ "$res" == "''hey" ] || err $LINENO

# offset

res=$($com <<< 'A=abc; echo ${A:1}' )
[ "$res" = "bc" ] || err $LINENO

res=$($com <<< 'A=あいうえお; echo ${A:2}' )
[ "$res" = "うえお" ] || err $LINENO

res=$($com <<< 'A=あいうえお; echo ${A:1 + 1 }' )
[ "$res" = "うえお" ] || err $LINENO

res=$($com <<< 'A=あいうえお; echo ${A:1 + 1:1}' )
[ "$res" = "う" ] || err $LINENO

res=$($com <<< 'A=あいうえお; echo ${A:1 + 1:2}' )
[ "$res" = "うえ" ] || err $LINENO

res=$($com <<< 'A=あいうえお; echo ${A:1 + 1:9}' )
[ "$res" = "うえお" ] || err $LINENO

res=$($com <<< 'A=あいうえお; echo ${A:1 + 1:}' )
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'A=あいうえお; echo ${A:}' )
[ "$?" = 1 ] || err $LINENO
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'A=あ; echo ${A: }' )
[ "$res" = "あ" ] || err $LINENO

res=$($com <<< 'A=あいうえお; echo ${A:6}' )
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'A=usr/local/bin/bash; echo ${A#*/}' )
[ "$res" = "local/bin/bash" ] || err $LINENO

res=$($com <<< 'A=usr/local/bin/bash; echo ${A##*/}' )
[ "$res" = "bash" ] || err $LINENO

res=$($com <<< 'A=usr/local/bin/bash; echo ${A%/*}' )
[ "$res" = "usr/local/bin" ] || err $LINENO

res=$($com <<< 'A=usr/local/bin/bash; echo ${A%%/*}' )
[ "$res" = "usr" ] || err $LINENO

res=$($com <<< 'A="あいう うえお"; echo ${A#*う う}' )
[ "$res" = "えお" ] || err $LINENO

res=$($com <<< 'A="[["; echo ${A%%[[(]}' )
[ "$res" = "[" ] || err $LINENO

# replace

res=$($com -c 'A="あいう うえお"; echo ${A/あ/}' )
[ "$res" = "いう うえお" ] || err $LINENO

res=$($com -c 'A="あいう うえお"; echo ${A/あ//}' )
[ "$res" = "/いう うえお" ] || err $LINENO

res=$($com -c 'A="あいう うえお"; echo ${A/い/え}' )
[ "$res" = "あえう うえお" ] || err $LINENO

res=$($com -c 'A="あいう うえお"; echo ${A/いう/えええeee}' )
[ "$res" = "あえええeee うえお" ] || err $LINENO

res=$($com -c 'A="あいう うえお"; echo ${A//う/えええeee}' )
[ "$res" = "あいえええeee えええeeeえお" ] || err $LINENO

res=$($com -c 'A="あいう いうえお"; echo ${A//いう/えええeee}' )
[ "$res" = "あえええeee えええeeeえお" ] || err $LINENO

res=$($com -c 'A="あいう いうえお"; echo ${A/#いう/えええeee}' )
[ "$res" = "あいう いうえお" ] || err $LINENO

res=$($com -c 'A="あいう いうえお"; echo ${A/#あいう/えええeee}' )
[ "$res" = "えええeee いうえお" ] || err $LINENO

res=$($com -c 'A="あいう いうえお"; echo ${A/%えお/えええeee}' )
[ "$res" = "あいう いうえええeee" ] || err $LINENO

res=$($com -c 'A="あいうえお いうえお"; echo ${A/%えお/えええeee}' )
[ "$res" = "あいうえお いうえええeee" ] || err $LINENO

res=$($com -c 'A="あいうえお"; echo ${A/%あ/えええeee}' )
[ "$res" = "あいうえお" ] || err $LINENO

res=$($com <<< 'a=abca ; echo @${a//a}@')
[ "$res" = "@bc@" ] || err $LINENO

res=$($com <<< 'a=abca ; echo @${a//a/}@')
[ "$res" = "@bc@" ] || err $LINENO

res=$($com <<< 'a=" " ; echo @${a/[[:space:]]/}@')
[ "$res" = "@@" ] || err $LINENO

res=$($com <<< 'a="  " ; echo @${a/[[:space:]]/}@')
[ "$res" = "@ @" ] || err $LINENO

res=$($com <<< 'a="  " ; echo @${a//[[:space:]]/}@')
[ "$res" = "@@" ] || err $LINENO

res=$($com <<< 'a=abc; echo ${a[0]//a/!}')
[ "$res" == '!bc' ] || err $LINENO

res=$($com << 'EOF'
a=(abc def)
eval a2=("${a[@]/#/\"-iname \'\"}")
echo ${a2[0]}
echo ${a2[1]}
EOF
)
[ "$res" == "-iname 'abc
-iname 'def" ] || err $LINENO

# case conv.

res=$($com <<< 'a=abc; echo ${a^?}')
[ "$res" == 'Abc' ] || err $LINENO

### IRREGULAR INPUT TEST ###

res=$($com <<< 'eeeeeecho hoge')
[ "$?" = 127 ] || err $LINENO

res=$($com <<< ';')
[ "$?" = 2 ] || err $LINENO

res=$($com <<< ';a')
[ "$?" = 2 ] || err $LINENO

### PIPELINE ###

res=$($com <<< 'seq 10 | rev | tail -n 1')
[ "$res" = "01" ] || err $LINENO

res=$($com <<< 'seq 10 |
	rev | tail -n 1')
[ "$res" = "01" ] || err $LINENO

res=$($com <<< 'seq 10 |    

	  rev | tail -n 1')
[ "$res" = "01" ] || err $LINENO

res=$($com <<< 'seq 10 |  #コメントだよ

#コメントだよ
    #こめんとだよ

	  rev | tail -n 1')
[ "$res" = "01" ] || err $LINENO

res=$($com <<< 'seq 10 |   | head -n 1')
[ "$?" = "2" ] || err $LINENO

### COMMENT ###

res=$($com <<< 'echo a #aaaaa')
[ "$res" = "a" ] || err $LINENO

res=$($com <<< '
#comment comment
   #comment comment
echo a #aaaaa
#comment comment
')
[ "$res" = "a" ] || err $LINENO

res=$($com <<< '(echo a) #aaaaa')
[ "$res" = "a" ] || err $LINENO

res=$($com <<< '(echo a)#aaaaa')
[ "$res" = "a" ] || err $LINENO

res=$($com <<< '{ echo a; }#aaaaa')
[ "$res" != "a" ] || err $LINENO

res=$($com <<< '{ echo a; } #aaaaa')
[ "$res" = "a" ] || err $LINENO

### NEW LINE ###

res=$($com <<< 'e\
c\
ho hoge')
[ "$res" = "hoge" ] || err $LINENO

res=$($com <<< 'e\
c\
ho \
hoge')
[ "$res" = "hoge" ] || err $LINENO

res=$($com <<< 'echo hoge |\
rev')
[ "$res" = "egoh" ] || err $LINENO

res=$($com <<< 'echo hoge |\
& rev')
[ "$res" = "egoh" ] || err $LINENO

res=$($com <<< ' (seq 3; seq 3) | grep 3 | wc -l | tr -dc 0-9')
[ "$res" = "2" ] || err $LINENO

res=$($com <<< 'ls |  | rev')
[ "$?" == "2" ] || err $LINENO

### JOB PARSE TEST ###

res=$($com <<< '&& echo a')
[ "$?" == "2" ] || err $LINENO
[ "$res" == "" ] || err $LINENO

res=$($com <<< 'echo a
&& echo b')
[ "$?" == "2" ] || err $LINENO

res=$($com <<< 'echo a &\
& echo b')
[ "$res" == "a
b" ] || err $LINENO

res=$($com <<< 'echo a &&\
echo b')
[ "$res" == "a
b" ] || err $LINENO

res=$($com <<< 'echo a &&
echo b')
[ "$res" == "a
b" ] || err $LINENO

res=$($com <<< 'echo a &&



echo b')
[ "$res" == "a
b" ] || err $LINENO

res=$($com <<< 'echo a ||
echo b')
[ "$res" == "a" ] || err $LINENO

res=$($com <<< 'echo a \
&& echo b')
[ "$res" == "a
b" ] || err $LINENO

# double quotation

res=$($com <<< 'echo "*"')
[ "$res" == "*" ] || err $LINENO

res=$($com <<< 'echo "{a,{b},c}"')
[ "$res" == "{a,{b},c}" ] || err $LINENO

export RUSTY_BASH_A='a
b'
res=$($com <<< 'echo "$RUSTY_BASH_A"')
[ "$res" == "a
b" ] || err $LINENO

res=$($com <<< 'echo "$BASH{PID,_SUBSHELL}"')
[ "${res: -15}" == "{PID,_SUBSHELL}" ] || err $LINENO

res=$($com <<< 'echo "\$HOME"')
[ "$res" == '$HOME' ] || err $LINENO

res=$($com <<< 'echo "\a"')
[ "$res" == '\a' ] || err $LINENO

res=$($com <<< 'echo "\\"')
[ "$res" == '\' ] || err $LINENO

res=$($com <<< 'echo "a   b"')
[ "$res" == 'a   b' ] || err $LINENO

res=$($com <<< 'echo "a
b
c"')
[ "$res" == 'a
b
c' ] || err $LINENO

res=$($com <<< 'echo "')
[ "$?" == 2 ] || err $LINENO

res=$($com <<< 'echo "" a')
[ "$res" == " a" ] || err $LINENO


# single quoted

res=$($com <<< "echo '' a")
[ "$res" == " a" ] || err $LINENO

### WHILE TEST ###

res=$($com <<< 'touch /tmp/rusty_bash ; while [ -f /tmp/rusty_bash ] ; do echo wait ; rm /tmp/rusty_bash ; done')
[ "$res" == "wait" ] || err $LINENO

res=$($com <<< 'rm -f /tmp/rusty_bash ; while [ -f /tmp/rusty_bash ] ; do echo wait ; rm /tmp/rusty_bash ; done')
[ "$res" == "" ] || err $LINENO

res=$($com <<< 'while false ; do echo do not come here ; done')
[ "$?" == 0 ] || err $LINENO
[ "$res" == "" ] || err $LINENO

### ARG TEST ###

# escaping

res=$($com <<< "echo a\ \ \ a")
[ "$res" == "a   a" ] || err $LINENO

res=$($com <<< 'echo \(')
[ "$res" == "(" ] || err $LINENO

# quotation

res=$($com <<< "echo 'abc'")
[ "$res" == "abc" ] || err $LINENO

res=$($com <<< "echo 'abあいうc'")
[ "$res" == "abあいうc" ] || err $LINENO

res=$($com <<< "echo 123'abc'")
[ "$res" == "123abc" ] || err $LINENO

res=$($com <<< "echo 123'abc'def")
[ "$res" == "123abcdef" ] || err $LINENO

res=$($com <<< 'echo "\""')
[ "$res" == '"' ] || err $LINENO

res=$($com <<< 'echo "\`"' )
[ "$res" = "\`" ] || err $LINENO

# parameter expansion

res=$($com <<< 'echo $')
[ "$res" == "$" ] || err $LINENO

res=$($com <<< 'echo $?')
[ "$res" == "0" ] || err $LINENO

res=$($com <<< 'echo ${?}')
[ "$res" == "0" ] || err $LINENO

res=$($com <<< 'ls aaaaaaaa ; echo $?')
[ "$res" != "0" ] || err $LINENO

res=$($com <<< 'echo $BASH{PID,_SUBSHELL} | sed -E "s@[0-9]+@num@"')
[ "$res" == "num 0" ] || err $LINENO

res=$($com <<< 'echo ${BASHPID} ${BASH_SUBSHELL} | sed -E "s@[0-9]+@num@"')
[ "$res" == "num 0" ] || err $LINENO

res=$($com <<< 'echo ${ ')
[ "$?" == "2" ] || err $LINENO
[ "$res" == "" ] || err $LINENO

res=$($com <<< 'echo ${ A}')
[ "$?" == "1" ] || err $LINENO
[ "$res" == "" ] || err $LINENO

res=$($com <<< 'echo ${A }')
[ "$?" == "1" ] || err $LINENO
[ "$res" == "" ] || err $LINENO

res=$($com <<< 'echo ${_A32523j2}')
[ "$?" == "0" ] || err $LINENO
[ "$res" == "" ] || err $LINENO

res=$($com <<< 'echo ${_A32*523j2}')
[ "$?" == "1" ] || err $LINENO
[ "$res" == "" ] || err $LINENO

res=$($com <<< 'echo ${$,$} | grep "[^0-9]"')
[ "$?" == "1" ] || err $LINENO
[ "$res" == "" ] || err $LINENO

res=$($com <<< 'set a b c;echo $@')
[ "$res" == "a b c" ] || err $LINENO

res=$($com <<< 'A=あいうえおX; echo ${#A}')
[ "$res" == "6" ] || err $LINENO

res=$($com <<< 'A=(aaa bbbb); echo ${#A}; echo ${#A[1]}; echo ${#A[@]}; echo ${#A[*]}')
[ "$res" == "3
4
2
2" ] || err $LINENO

# tilde

res=$($com <<< 'echo ~ | grep -q /')
[ "$?" == "0" ] || err $LINENO

res=$($com <<< 'echo ~root')
[ "$res" == "/root" -o "$res" == "/var/root" ] || err $LINENO

res=$($com <<< 'cd /; cd /etc; echo ~+; echo ~-')
[ "$res" == "/etc
/" ] || err $LINENO

res=$($com -c 'echo =~/:~/ | grep "~"')
[ $? -eq 0 ] || err $LINENO

res=$($com -c 'A=(~/:~/); echo $A | grep "~"')
[ $? -eq 0 ] || err $LINENO

res=$($com -c 'A=~/:~/; echo $A | grep "~"')
[ $? -eq 1 ] || err $LINENO

res=$($com -c 'A[0]=~/:~/; echo $A | grep "~"')
[ $? -eq 1 ] || err $LINENO


# split

export RUSTY_BASH_A='a
b'
res=$($com <<< 'echo $RUSTY_BASH_A')
[ "$res" == "a b" ] || err $LINENO

export RUSTY_BASH_A='a
b'
res=$($com <<< 'echo $RUSTY_BASH_A$RUSTY_BASH_A')
[ "$res" == "a ba b" ] || err $LINENO

export RUSTY_BASH_A='a
b'
res=$($com <<< 'echo ${RUSTY_BASH_A}c')
[ "$res" == "a bc" ] || err $LINENO

export RUSTY_BASH_A='a
b
'
res=$($com <<< 'echo ${RUSTY_BASH_A}c')
[ "$res" == "a b c" ] || err $LINENO

res=$($com <<< 'mkdir -p tmp; cd tmp; echo .* | grep -F ". .."; cd ..; rmdir tmp')
[ "$res" == '' ] || err $LINENO

res=$($com <<< 'mkdir tmp; cd tmp; echo .*/ | grep -F "../ ./"; cd ..; rmdir tmp')
[ "$res" == '' ] || err $LINENO

# command expansion

res=$($com <<< 'echo a$(seq 2)b')
[ "$res" == "a1 2b" ] || err $LINENO

res=$($com <<< 'echo a$()b')
[ "$res" == "ab" ] || err $LINENO

res=$($com <<< 'echo "a$(seq 2)b"')
[ "$res" == "a1
2b" ] || err $LINENO

res=$($com <<< 'echo $(pwd)')
[ "$res" == "$(pwd)" ] || err $LINENO

res=$($com <<< 'echo $(pwd) a')
[ "$res" == "$(pwd) a" ] || err $LINENO

res=$($com <<< 'echo {,,}$(date "+%w")')
[ "$res" == "$(echo {,,}$(date "+%w"))" ] || err $LINENO

res=$($com <<< 'echo $(date) | grep "  "')
[ "$?" == "1" ] || err $LINENO

res=$($com <<< 'a=$(seq 2)
echo "$a"
')
[ "$res" == "1
2" ] || err $LINENO

res=$($com <<< 'a=$(
echo a
echo b
)
echo "$a"
')
[ "$res" == "a
b" ] || err $LINENO

res=$($com <<< 'echo `echo aaa`' )
[ "$res" = "aaa" ] || err $LINENO


### PROCESS SUBSTITUTION ###

res=$($com <<< 'rev <(echo abc)' )
[ "$res" = "cba" ] || err $LINENO

res=$($com <<< 'rev < <(echo abc)' )
[ "$res" = "cba" ] || err $LINENO

# symbol

res=$($com <<< 'echo ]')
[ "$res" == "]" ] || err $LINENO

# $"..."

res=$($com <<< 'echo $"hello"')
[ "$res" = "hello" ] || err $LINENO

### ALIAS ###

res=$($com <<< "shopt -s expand_aliases;
alias a=
a")
[ $? -eq 0 ] || err $LINENO

res=$($com <<< "shopt -s expand_aliases;
alias a=#
a")
[ $? -eq 0 ] || err $LINENO

res=$($com <<< "shopt -s expand_aliases;
alias a='echo b'
a")
[ "$res" = "b" ] || err $LINENO

res=$($com -c "shopt -s expand_aliases;
alias a='echo b'
a")
[ "$res" = "b" ] || err $LINENO

res=$($com <<< 'shopt -s expand_aliases; alias a="b=()"
a')
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'shopt -s expand_aliases; alias a="b=(1 2 3)"
a;echo ${b[1]}') 
[ "$res" = "2" ] || err $LINENO

echo $0 >> ./ok
