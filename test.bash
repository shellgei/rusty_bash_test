#!/bin/bash -xv
# SPDX-FileCopyrightText: 2023 Ryuichi Ueda ryuichiueda@gmail.com
# SPDX-License-Identifier: GPL-3.0-or-later

err () {
	echo "ERROR!" FILE: $0, LINENO: $1
	exit 1
}

export SUSH_COMPAT_TEST_MODE=0

cd $(dirname $0)

repo_dir=${1:-~/GIT/rusty_bash}
test_dir="$PWD"
com="$repo_dir/target/release/sush"
cd "$repo_dir"

cargo build || err $LINENO
cargo build --release || err $LINENO
cargo --version

cd "$test_dir"

: > error
: > ok

./test_job.bash nobuild "$repo_dir" &
./test_case.bash nobuild "$repo_dir" &
./test_substitution.bash nobuild "$repo_dir" &
./test_others.bash nobuild "$repo_dir" &
./test_redirects.bash nobuild "$repo_dir" &
./test_calculation.bash nobuild "$repo_dir" &
./test_compound.bash nobuild "$repo_dir" &
./test_brace.bash nobuild "$repo_dir" &
./test_builtins.bash nobuild "$repo_dir" &
./test_options.bash nobuild "$repo_dir" &
./test_parameters.bash nobuild "$repo_dir" &
./test_glob.bash nobuild "$repo_dir" &
./test_ansi_c_quoting.bash nobuild "$repo_dir" &
./test_fixed.bash nobuild "$repo_dir" &
./test_param_substitutions.bash nobuild "$repo_dir" &
./test_array.bash nobuild "$repo_dir" &
./test_fixed_v1.2.0.bash nobuild "$repo_dir" &
./test_fixed_v1.2.1.bash nobuild "$repo_dir" &
./test_fixed_v1.2.2.bash nobuild "$repo_dir" &

wait 

head ./ok ./error

[ $(cat ./error | wc -l) == "0" ]  || err $LINENO

echo OK $0
