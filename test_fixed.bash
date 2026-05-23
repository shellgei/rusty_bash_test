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

#res=$($com <<< 'enable | wc -l')
#[ "$res" -gt 10 ] || err $LINENO
#
#res=$($com <<< 'enable -n readonly ; enable | grep readonly')
#[ "$?" -ne 0 ] || err $LINENO
#
#if [ "$(uname)" = Linux ] ; then
#	res=$($com <<< 'ulimit -n 256; ulimit -n')
#	[ "$res" = "256" ] || err $LINENO
#fi
#
#res=$($com <<< 'read -ru3 x 3< <(echo bbb); echo $x')
#[ "$res" = "bbb" ] || err $LINENO
#
#res=$($com <<< 'A=abc; echo ${A::}')
#[ "$?" -eq 0 ] || err $LINENO
#[ "$res" = "" ] || err $LINENO
#
#res=$($com <<< 'A=abc; echo ${A::2}')
#[ "$?" -eq 0 ] || err $LINENO
#[ "$res" = "ab" ] || err $LINENO
#
#res=$($com <<< 'echo ${a"}')
#[ "$?" -eq 2 ] || err $LINENO
#
#if [ "$(uname)" = Linux ] ; then
#	res=$($com <<< 'coproc REFLECT { cat - ; } ; kill $REFLECT_PID; sleep 1')
#	ps u | grep '[c]at -'
#	[ "$?" -eq 1 ] || { killall cat ; err $LINENO ; }
#fi
#
#res=$($com <<< 'exec 4>/tmp/exec4 ; echo aaa >&4; cat /tmp/exec4; rm /tmp/exec4')
#[ "$res" = "aaa" ] || err $LINENO
#
#res=$($com <<< 'exec 3>/tmp/exec3 ; echo aaa >&3; cat /tmp/exec3; rm /tmp/exec3')
#[ "$res" = "aaa" ] || err $LINENO
#
#res=$($com <<< 'exec 5>/tmp/exec5; exec 4<&5-; echo hoge >&4; cat /tmp/exec5 ;rm /tmp/exec5')
#[ "$res" = "hoge" ] || err $LINENO
#
#res=$($com <<< 'coproc cat - ; exec 3<&${COPROC[1]}- ; echo ${COPROC[@]}')
#[ "$res" = "63 -1" ] || err $LINENO
#
#res=$($com <<< 'coproc cat - ; exec 3>&${COPROC[0]}- ; echo ${COPROC[@]}')
#[ "$res" = "-1 60" ] || err $LINENO

rm -f $tmp-*
echo $0 >> ./ok
exit

