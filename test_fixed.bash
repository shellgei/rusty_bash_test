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

res=$($com -c 'echo A=~/:~/ | grep "~"')
[ $? -eq 1 ] || err $LINENO

res=$($com -c 'echo =~/:~/ | grep "~"')
[ $? -eq 0 ] || err $LINENO

res=$($com -c 'A=(~/:~/); echo $A | grep "~"')
[ $? -eq 0 ] || err $LINENO

res=$($com -c 'A=~/:~/; echo $A | grep "~"')
[ $? -eq 1 ] || err $LINENO

res=$($com -c 'A[0]=~/:~/; echo $A | grep "~"')
[ $? -eq 1 ] || err $LINENO

res=$($com -c 'set -m; sleep 1 & %%')
[ $? -eq 0 ] || err $LINENO

res=$($com -c 'sleep 1 & %%')
[ $? -eq 1 ] || err $LINENO

res=$($com -o posix -c 'set -o | grep posix | grep on' )
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'echo >&3')
[ $? -eq 1 ] || err $LINENO

res=$($com <<< 'exec 3>&2 ; echo >&3')
[ $? -eq 0 ] || err $LINENO

res=$($com <<< 'sleep 1 & a=$! ; wait -p b -n ; echo $((a -  b))')
[ "$res" = "0" ] || err $LINENO

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

