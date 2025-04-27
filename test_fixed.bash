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

res=$($com <<< '< /dev/null x=a ; echo $x')
[ "$res" = "a" ] || err $LINENO

res=$($com <<< 'shopt -s expand_aliases; alias a="b=()"
a')
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'shopt -s expand_aliases; alias a="b=(1 2 3)"
a;echo ${b[1]}') 
[ "$res" = "2" ] || err $LINENO

cat << 'EOF' > $tmp-script
cat << FIN | grep '"'
"$-"
FIN
EOF
res=$($com $tmp-script)
[ $? -eq 0 ] || err $LINENO

rm -f $tmp-*
echo $0 >> ./ok
exit

