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

cat << 'EOF' > $tmp-script
echo $(cat << FIN | rev
abc
FIN
echo def)
EOF
res=$($com $tmp-script)
[ "$res" = "cba def" ] || err $LINENO

cat << 'EOF' > $tmp-script
cat << FIN
$'\x31'
FIN
EOF
res=$($com $tmp-script)
[ "$res" = "$'\x31'" ] || err $LINENO

cat << 'EOF' > $tmp-script
a=ABC
cat << FIN
$a
DEF
FIN
EOF
res=$($com $tmp-script)
[ "$res" = "ABC
DEF" ] || err $LINENO

cat << 'EOF' > $tmp-script
a=ABC
cat << 'FIN'
$a
DEF
FIN
EOF
res=$($com $tmp-script)
[ "$res" = '$a
DEF' ] || err $LINENO

res=$($com << 'EOF'
z=$'\v\f\a\b'
case $z in
	$'\v\f\a\b') echo ok ;;
esac
EOF
)
[ "$res" = "ok" ] || err $LINENO

res=$($com <<< '
cat << EOF | rev
abc
EOF
')
[ "$res" = "cba" ] || err $LINENO

res=$($com <<< 'echo $"hello"')
[ "$res" = "hello" ] || err $LINENO

res=$($com <<< "echo $'\r\e\a' | xxd -ps")
[ "$res" = "0d1b070a" ] || err $LINENO

res=$($com <<< 'A=(1 2 3) ; declare -r A[1] ; A[0]=aaa ; echo ${A[@]}')
[ "$res" = "1 2 3" ] || err $LINENO

res=$($com <<< 'unset a ; a=abcde ; declare -a a ; echo ${a[0]}')
[ "$res" = "abcde" ] || err $LINENO

res=$($com <<< 'test=(first & second)')
[ "$?" -eq "1" ] || err $LINENO

rm -f $tmp-*
echo $0 >> ./ok
exit

### issue 130 ###
### input-line.sh test of Bash ###

# It works.
cat << 'EOF' > $tmp-script
read a
echo @$a
EOF
chmod +x $tmp-script
res=$(bash << EOF
$com $tmp-script
OH
EOF
)
[ "$res" = "@OH" ] || err $LINENO

# It doesn't work.
# Maybe the exec-on-close is applied to
# the file discriptor of $com << EOF. 

chmod +x $tmp-script
res=$($com << EOF
$com $tmp-script
OH
EOF
)
[ "$res" = "@OH" ] || err $LINENO

res=$($com <<< 'a[n]=++n ; echo ${a[1]}')
[ "$res" = "1" ] || err $LINENO

