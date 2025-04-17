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

res=$($com <<< 'case "]" in [a]] ) echo NG ;; esac')
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'case "]" in [\]] ) echo OK ;; esac')
[ "$res" = "OK" ] || err $LINENO

res=$($com <<< 'case "]" in []] ) echo OK ;; esac')
[ "$res" = "OK" ] || err $LINENO

res=$($com <<< 'case "]" in [^]] ) echo NG ;; esac')
[ "$res" = "" ] || err $LINENO

res=$($com <<< 'case 1 in $(( 1/ 0 )) ) echo NG ;; *) echo NG; esac')
[ "$res" = "" ] || err $LINENO


res=$($com <<< 'x=0 y=1 ; case 1 in $((y=0)) ) ;; $((x=1)) ) ;& $((x=2)) ) echo $x.$y ;; esac')
[ "$res" = "1.0" ] || err $LINENO

res=$($com <<< 'shopt -o -s posix')
[ "$?" -eq "0" ] || err $LINENO

res=$($com <<< 'readonly x=1; x=2 ; echo $x')
[ "$res" = "1" ] || err $LINENO


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

cat << 'EOF' > $tmp-script
echo OK | ( while read line ; do echo $line ; done )
ああああああ！
EOF
res=$($com <<< "source $tmp-script")
[ "$res" = "OK" ] || err $LINENO

res=$($com <<< 'declare -i i=1 j=2 k=3
echo $((i += j += k))
echo $i,$j,$k
')
[ "$res" = "6
6,5,3" ] || err $LINENO

res=$($com <<< '[[
# hogehoge
1 -eq 1 &&
	#fugefuge
1 -eq 1
]]')
[ "$?" = 0 ] || err $LINENO

res=$($com <<< 'echo $(( 3 - 4 + 5))')
[ "$res" = "4" ] || err $LINENO

res=$($com <<< 'echo ${#a[@]}')
[ "$res" = "0" ] || err $LINENO

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

res=$($com <<< 'rev <<- EOF
abc
あいう
EOF
')
[ "$res" == "cba
ういあ" ] || err $LINENO

res=$($com <<< 'rev <<- EOF
	abc
	あいう
	EOF
')
[ "$res" == "cba
ういあ" ] || err $LINENO

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
rm -f $tmp-*
echo $0 >> ./ok
exit

### issue 130 ###
### input-line.sh test of Bash ###

# It works.
cat << 'EOF' > $tmp-script
read a
echo @$a
EOF
chmod +x $tmp-script
res=$(bash << EOF
$com $tmp-script
OH
EOF
)
[ "$res" = "@OH" ] || err $LINENO

# It doesn't work.
# Maybe the exec-on-close is applied to
# the file discriptor of $com << EOF. 

chmod +x $tmp-script
res=$($com << EOF
$com $tmp-script
OH
EOF
)
[ "$res" = "@OH" ] || err $LINENO

res=$($com <<< 'a[n]=++n ; echo ${a[1]}')
[ "$res" = "1" ] || err $LINENO

