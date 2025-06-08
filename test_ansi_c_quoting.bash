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
com="$repo_dir/target/release/sush"
cd "$repo_dir"
tmp=/tmp/$$

[ "$1" == "nobuild" ] || cargo build --release || err $LINENO
cd "$test_dir"

# this test case is never fulfilled until we use String type
res=$($com -b <<- FIN
echo -n $'\xdb' | xxd -p
FIN
)
[ "$res" == "db" ] || err $LINENO

res=$($com <<- 'FIN'
echo $'aaa'
FIN
)
[ "$res" == "aaa" ] || err $LINENO

res=$($com <<- 'FIN'
echo $'a\nb'
FIN
)
[ "$res" == "a
b" ] || err $LINENO

res=$($com <<- 'FIN'
echo $'\c2\cr\cR\c-\c[\c]\c^\c<'
FIN
)
[ "$res" == $'\c2\cr\cR\c-\c[\c]\c^\c<' ] || err $LINENO

res=$($com <<- 'FIN'
echo $'\110\19\9\477\x40\x7A\x7a\x9Z' 
FIN
)
[ "$res" == $'\110\19\9\477\x40\x7A\x7a\x9Z' ] || err $LINENO

res=$($com <<- 'FIN'
echo $'\u1234\uffFF' 
FIN
)
[ "$res" == $'\u1234\uffFF' ] || err $LINENO

res=$($com <<- 'FIN'
echo $'\u40X' 
FIN
)
[ "$res" == $'\u40X' ] || err $LINENO

res=$($com <<- 'FIN'
echo $'\U110000' 
FIN
)
[ "$res" == $'\U110000' ] || err $LINENO

res=$($com -c 'echo ${@[0]}' )
[ $? = 1 ] || err $LINENO
[ "$res" = "" ] || err $LINENO

res=$($com <<< "echo $'\r\e\a' | xxd -ps")
[ "$res" = "0d1b070a" ] || err $LINENO

echo $0 >> ./ok
