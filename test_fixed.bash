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

res=$($com /bin/sh)
[ $? -eq 126 ] || err $LINENO

res=$($com << 'EOF'
trap 'echo USR1' USR1
kill -s USR1 $$
sleep 0.5
sleep 0.5
EOF
)
[ "$res" = "USR1" ] || err $LINENO

cat << 'EOF' | $com
trap 'true' EXIT
false
EOF
[ $? -eq 1 ] || err $LINENO

res=$($com <<< 'PATH=/ ; command -pv bash')
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'A=久里浜YRP野比長沢; echo ${A:3:-1}')
[ "$res" = "YRP野比長" ] || err $LINENO

res=$($com <<< 'A=久里浜YRP野比長沢; echo ${A:3:-2}')
[ "$res" = "YRP野比" ] || err $LINENO

res=$($com <<< "echo {$'\x0'..a}")
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'printf \\0\\7 | xxd -ps')
[ "$res" = "0007" ] || err $LINENO

#res=$($com <<< 'printf \\777 | xxd -ps')
#[ "$res" = "ff" ] || err $LINENO

rm -f $tmp-*
echo $0 >> ./ok
exit

