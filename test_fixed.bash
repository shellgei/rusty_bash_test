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

res=$($com <<< 'for i in a b c; do echo $i; continue; echo bad-$i ; done; echo end-1')
[ "$res" == 'a
b
c
end-1' ] || err $LINENO


res=$($com <<< 'f() { echo "-${*-x}-" ; } ; f ""')
[ "$res" == '--' ] || err $LINENO

res=$($com -c 'echo F=~')
[ "$res" != 'F=~' ] || err $LINENO

res=$($com -c 'echo ${A:-\a}')
[ "$res" == 'a' ] || err $LINENO

res=$($com -c 'echo "${A:-\a}"')
[ "$res" == '\a' ] || err $LINENO

res=$($com -c 'echo ${A:-~}')
[ "$res" != '~' ] || err $LINENO

res=$($com -c 'echo "${A:-~}"')
[ "$res" = '~' ] || err $LINENO

res=$($com -c '
cat << !
~
!
')
echo "$res" | grep '~' || err $LINENO

res=$($com -c '
cat << !
~/bin
!
')
echo "$res" | grep '~/bin' || err $LINENO

res=$($com -c ': ${A:=~}; echo $A')
echo "$res" | grep '^/' || err $LINENO

res=$($com -c ': ${A:=~:aa}; echo $A')
echo "$res" | grep '^/' || err $LINENO

res=$($com -c ': ${A:=~/bin:~/bin2}; echo $A')
echo "$res" | grep '^/.*~' || err $LINENO

res=$($com -c ': ${A:=B=~/bin:~/bin2}; echo $A')
[ "$res" = 'B=~/bin:~/bin2' ] || err $LINENO

res=$($com -c 'B=aaa;C=D=~/bin:$B; echo $C')
[ "$res" = 'D=~/bin:aaa' ] || err $LINENO



rm -f $tmp-*
echo $0 >> ./ok
exit

