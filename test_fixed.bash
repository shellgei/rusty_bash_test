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

res=$($com << 'EOF'
f(){ local a=bbb ; g ; declare -p a ;echo $? ; echo $a;  }
g(){ unset a ; }

f
shopt -s localvar_unset
f
EOF
)
[ "$res" = '1

declare -- a
0' ] || err $LINENO


res=$($com << 'EOF'
a=(aaa bbb)
f(){ local a; echo ${a[@]} ; }

f
shopt -s localvar_inherit
f
EOF
)
[ "$res" = '
aaa bbb' ] || err $LINENO

res=$($com << 'EOF'
a=bbb
f(){ local a; echo $a ; }

f
shopt -s localvar_inherit
f
EOF
)
[ "$res" = '
bbb' ] || err $LINENO


res=$($com << 'EOF'
f1(){ local a=aaa ; f2 ; }
f2(){ echo $a ; }

f1
EOF
)
[ "$res" = 'aaa' ] || err $LINENO

res=$($com << 'EOF'
f1(){ local a=aaa ; f2 ; }
f2(){ local a; echo $a ; }

shopt -s localvar_inherit
f1
EOF
)
[ "$res" = 'aaa' ] || err $LINENO


res=$($com <<<  'foo=$(cat <<EOF
hi
EOF)
echo $foo'
)
[ $? -eq 0 ] || err $LINENO
[ "$res" = 'hi' ] || err $LINENO

res=$($com <<<  'foo=`cat <<EOF
hi
EOF`
echo $foo'
)
[ $? -eq 0 ] || err $LINENO
[ "$res" = 'hi' ] || err $LINENO

res=$($com << 'EOF'
f () { local 'c=$(date +%N)' ; echo $c ; }
f | grep date
EOF
)
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'A=$(cat << EOF
aaa
EOF)
echo $A
')
[ $? -eq 0 ] || err $LINENO
[ "$res" = 'aaa' ] || err $LINENO

res=$($com <<< 'A=`cat << EOF
aaa
EOF`
echo $A
')
[ $? -eq 0 ] || err $LINENO
[ "$res" = 'aaa' ] || err $LINENO

res=$($com <<< 'A=$(cat << EOF
aaa
EOF )
echo $A
')
[ $? -eq 0 ] || err $LINENO
[ "$res" = 'aaa' ] || err $LINENO

res=$($com <<< "cat << EOF
aaa
")
[ $? -eq 0 ] || err $LINENO
[ "$res" = 'aaa' ] || err $LINENO

res=$($com <<< "echo 123 | tee >(rev) | rev --")
[ "$res" = '321
123' ] || err $LINENO

rm -f $tmp-*
echo $0 >> ./ok
exit

