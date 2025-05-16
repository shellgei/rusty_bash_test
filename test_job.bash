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

[ "$1" == "nobuild" ] || cargo build --release || err $LINENO
cd "$test_dir"

### JOB TEST ###

res=$($com <<< 'sleep 1 & sleep 2 & sleep 3 & jobs')
echo "$res" | grep -F '[1] ' || err $LINENO
echo "$res" | grep -F '[2]- ' || err $LINENO
echo "$res" | grep -F '[3]+ ' || err $LINENO

res=$($com <<< 'sleep 5 | rev | cat & sleep 1 ; killall -SIGSTOP cat ; jobs')
echo "$res" | grep Stopped || err $LINENO

### JOBSPEC ###

res=$($com -c 'set -m; sleep 1 & %%')
[ $? -eq 0 ] || err $LINENO

res=$($com -c 'sleep 1 & %%')
[ $? -eq 1 ] || err $LINENO

### WAIT ###

res=$($com <<< 'sleep 1 & a=$! ; wait -p b -n ; echo $((a -  b))')
[ "$res" = "0" ] || err $LINENO

echo $0 >> ./ok
