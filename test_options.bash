#!/bin/bash -xv
# SPDX-FileCopyrightText: 2024 Ryuichi Ueda ryuichiueda@gmail.com
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

cat << 'EOF' > $tmp-script
echo $- | grep -q e ; echo $?
echo $@
EOF
chmod +x $tmp-script

res=$($com -e $tmp-script -a -b -c)
[ "$res" == "0
-a -b -c" ] || err $LINENO

### -c

res=$($com -c "echo a")
[ "$?" == "0" ] || err $LINENO
[ "$res" == "a" ] || err $LINENO

res=$($com -c "ech a")
[ "$?" == "127" ] || err $LINENO
[ "$res" == "" ] || err $LINENO

res=$(echo abc | $com -c "rev")
[ "$res" == "cba" ] || err $LINENO

res=$($com -c -)
[[ "$?" -eq 2 ]] || err $LINENO

res=$($com -c 'echo $@' a b c)
[ "$res" == "b c" ] || err $LINENO

res=$($com -c 'echo $0' a b c)
[ "$res" == "a" ] || err $LINENO

### -e

res=$($com <<< 'set -e ; false ; echo NG')
[ "$res" != "NG" ] || err $LINENO

res=$($com <<< 'set -e ; false | true ; echo OK')
[ "$res" == "OK" ] || err $LINENO

res=$($com <<< 'set -e ; ( false ) ; echo NG')
[ "$res" != "NG" ] || err $LINENO

res=$($com <<< 'set -e ; false || echo OK')
[ "$res" == "OK" ] || err $LINENO

res=$($com <<< 'set -e ; false || false ; echo NG')
[ "$res" == "" ] || err $LINENO

res=$($com <<< 'set -e ; while false ; do echo NG ; done ; echo OK')
[ "$res" == "OK" ] || err $LINENO

res=$($com <<< 'set -o pipefail; ls aaaa | false | true')
[ "$?" == "1" ] || err $LINENO

res=$($com <<< 'set -o pipefail; set -e; false | true ; echo NG')
[ "$res" == "" ] || err $LINENO

### -B

res=$($com <<< 'set +B; echo {a,b}')
[ "$res" == "{a,b}" ] || err $LINENO

### -o

res=$($com <<< 'set -o noglob; echo /etc/*')
[ "$res" = "/etc/*" ] || err $LINENO

res=$($com -o posix -c 'set -o | grep posix | grep on' )
[ $? -eq 0 ] || err $LINENO

### -m

res=$($com -c 'set +m; shopt -s lastpipe; echo a | read b; echo $b:$b')
[ "$res" = "a:a" ] || err $LINENO

### shopt ###

res=$($com <<< 'shopt -s execfail ; exec hohooh ; echo OK')
[ "$res" == "OK" ] || err $LINENO

echo $0 >> ./ok
