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

#res=$($com << 'EOF'
#a=('a b' 'c d' 'e f')
#IFS=
#set ${a[@]:1:2}
#echo $2
#EOF
#)
#[ "$res" == "e f" ] || err $LINENO


res=$($com << 'EOF'
echo "${dbg-'"'hey}"
EOF
)
[ "$res" == "''hey" ] || err $LINENO

cat << 'EOF' > $tmp-script
echo $- | grep -q e ; echo $?
echo $@
EOF
chmod +x $tmp-script

res=$($com -e $tmp-script -a -b -c)
[ "$res" == "0
-a -b -c" ] || err $LINENO

res=$($com -e $tmp-script -a -bc)
[ "$res" == "0
-a -bc" ] || err $LINENO


res=$($com <<< 'let a=(5 + 3) b=(4 + 7); echo $a $b')
[ "$res" == '8 11' ] || err $LINENO

res=$($com <<< 'echo $(eval echo b)')
[ "$res" == 'b' ] || err $LINENO

rm -f $tmp-*
echo $0 >> ./ok
exit

