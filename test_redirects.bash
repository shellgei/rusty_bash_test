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

rm -f /tmp/rusty_bash*

[ "$1" == "nobuild" ] || cargo build --release || err $LINENO
cd "$test_dir"

### REDIRECTS ###

# <, >, >>

res=$($com <<< 'cat < /etc/passwd | wc -l')
[ "$res" != "0" ] || err $LINENO

res=$($com <<< 'cat < /etc/passwd > /tmp/rusty_bash1 ; cat /tmp/rusty_bash1 | wc -l')
[ "$res" != "0" ] || err $LINENO

res=$($com <<< 'echo a > /tmp/rusty_bash1 ; echo b >> /tmp/rusty_bash1; cat /tmp/rusty_bash1')
[ "$res" = "a
b" ] || err $LINENO

# non-fork redirects

res=$($com <<< '
	cd /etc/
	cd /tmp
	cd - > /tmp/rusty_bash1
	cd - > /tmp/rusty_bash2
	cat /tmp/rusty_bash1
	cat /tmp/rusty_bash2
	pwd' | sed s@.private@@)
[ "$res" = "/etc
/tmp
/tmp" ] || err $LINENO

res=$($com <<< '
	cd /etc/
	cd /tmp
	{ cd - ; cd - ; /bin/echo a; } > /tmp/rusty_bash1
	{ cd - ; } > /tmp/rusty_bash2
	cat /tmp/rusty_bash1
	cat /tmp/rusty_bash2
	pwd' | sed s@.private@@)
[ "$res" = "/etc
/tmp
a
/etc
/etc" ] || err $LINENO

# 2>, 2>>

res=$($com <<< '
	ls /aaaa 2> /tmp/rusty_bash_$$
	ls /bbbb 2>> /tmp/rusty_bash_$$
	cat /tmp/rusty_bash_$$ | grep ls | wc -l
	' | tr -dc 0-9)
[ "$res" = "2" ] || err $LINENO

# &>

res=$($com <<< 'ls /etc/passwd aaaa &> /tmp/rusty_bash_o; cat /tmp/rusty_bash_o | wc -l | tr -dc 0-9')
[ "$res" == "2" ] || err $LINENO

# &> for non-fork redirects

res=$($com <<< '
	{ ls /etc/passwd aaaa ; } &> /tmp/rusty_bash_o
	cat /tmp/rusty_bash_o | wc -l | tr -dc 0-9')
[ "$res" == "2" ] || err $LINENO

res=$(LANG=C $com <<< '
	{ ls /etc/passwd aaaa ; } &> /tmp/rusty_bash_o
	cat /tmp/rusty_bash_o | wc -l
	#ちゃんと標準出力が原状復帰されているか調査
	{ ls /etc/passwd ; }
	{ ls aaaa ; } 2> /tmp/rusty_bash_o2
	cat /tmp/rusty_bash_o2 | wc -l
	' | tr -d '[:blank:]')
[ "$res" == "2
/etc/passwd
1" ] || err $LINENO

res=$($com <<< '
	cd /etc/
	cd /tmp
	{ cd - ; cd - ; /bin/echo a; } &> /tmp/rusty_bash1
	{ cd - ; } &> /tmp/rusty_bash2
	cat /tmp/rusty_bash1
	cat /tmp/rusty_bash2
	pwd' | sed s@.private@@)
[ "$res" = "/etc
/tmp
a
/etc
/etc" ] || err $LINENO

# >&

b=$(ls aaaaaaaaaaaaaa 2>&1 | wc -l)
res=$($com <<< 'ls aaaaaaaaaaaaaa 2>&1 | wc -l')
[ "$b" == "$res" ] || err $LINENO

#res=$($com <<< 'pwd 200>&100')  <- not passed on macOS of GitHub Actions, 20241019
#[ "$?" == "1" ] || err $LINENO

#res=$($com <<< 'ls 200>&100')  <- not passed on macOS of GitHub Actions, 20241019
#[ "$?" == "1" ] || err $LINENO

# with expansion

res=$($com <<< 'echo a > {a,b}' 2>&1)
[ "$?" == "1" ] || err $LINENO
[[ "$res" =~ ambiguous ]] || err $LINENO

# herestring

res=$($com <<< 'rev <<< あいう')
[ "$res" == "ういあ" ] || err $LINENO

res=$($com <<< 'cat <<< $(seq 3)')
[ "$res" == "1
2
3" ] || err $LINENO

if [ "$(uname)" = "Linux" ] ; then
	res=$($com <<< 'cat <<< $(seq 3000) | wc -l')
	[ "$res" == "3000" ] || err $LINENO

	res=$($com <<< 'cat <<< $(aaa) | wc -l')
	[ "$res" == "1" ] || err $LINENO
fi

res=$($com <<< 'read -a hoge <<< "A B C"; echo ${hoge[1]}')
[ "$res" = "B" ] || err $LINENO

res=$($com <<< 'read -a hoge <<< "A B C"; echo ${hoge[2]}')
[ "$res" = "C" ] || err $LINENO

# here documents

res=$($com <<< 'rev << EOF
abc
あいう
EOF
')
[ "$res" == "cba
ういあ" ] || err $LINENO

res=$($com <<< 'A=hoge ; rev << EOF
abc
あいう
$A
EOF
')
[ "$res" == "cba
ういあ
egoh" ] || err $LINENO

res=$($com << 'AAA'
while read a b ; do echo $a _ $b ; done << EOF
A B
A ()
t fofo                *(f*(o))
EOF
AAA
)
[ "$res" = "A _ B
A _ ()
t _ fofo *(f*(o))" ] || err $LINENO

res=$($com << 'AAA'
cat << "EOF"
abc
EOF
AAA
)
[ "$res" = 'abc' ] || err $LINENO

res=$($com <<< 'rev <<- EOF
abc
あいう
EOF
')
[ "$res" == "cba
ういあ" ] || err $LINENO

res=$($com <<< 'rev <<- EOF
	abc
	あいう
	EOF
')
[ "$res" == "cba
ういあ" ] || err $LINENO

## It works.
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

res=$($com << EOF
$com $tmp-script
OH
EOF
)
[ "$res" = "@OH" ] || err $LINENO

cat << 'EOF' > $tmp-script
echo abc | ( rev )
unset x
EOF
res=$(cat $tmp-script | $com)
[ "$res" = "cba" ] || err $LINENO

cat << 'EOF' > $tmp-script
echo abc | ( read x; echo $x )
unset x
EOF
res=$(cat $tmp-script | $com)
[ "$res" = "abc" ] || err $LINENO

cat << 'EOF' > $tmp-script
echo abc | { read x; echo $x  ; }
unset x
EOF
res=$(cat $tmp-script | $com)
[ "$res" = "abc" ] || err $LINENO

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

cat << 'EOF' > $tmp-script
cat << FIN
${none-a$'\01'b}
${none-ab}
FIN
EOF
res=$($com $tmp-script)
[ "$res" = "a$'\01'b
ab" ] || err $LINENO

cat << 'EOF' > $tmp-script
cat << FIN | grep '"'
"$-"
FIN
EOF
res=$($com $tmp-script)
[ $? -eq 0 ] || err $LINENO

# various

res=$($com <<< 'echo $(sleep 1 ; echo abc) $(echo cde) > /dev/stdout')
[ "$res" = "abc cde" ] || err $LINENO

res=$(echo 'cat
OH' | $com)
[ "$res" = "OH" ] || err $LINENO

res=$($com << EOF
$com -c cat
OH
EOF
)
[ "$res" = "OH" ] || err $LINENO

res=$($com <<< '
cat << EOF | rev
abc
EOF
')
[ "$res" = "cba" ] || err $LINENO

res=$($com <<< 'echo >&3')
[ $? -eq 1 ] || err $LINENO

res=$($com <<< 'exec 3>&2 ; echo >&3')
[ $? -eq 0 ] || err $LINENO

res=$($com <<< '< /dev/null x=a ; echo $x')
[ "$res" = "a" ] || err $LINENO

echo $0 >> ./ok
