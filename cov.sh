#!/bin/bash
# Rust Source-based Code Coverage for workspaces
# Author: Duyet Le <me@duyet.net>
# Ref: https://doc.rust-lang.org/stable/rustc/instrument-coverage.html
# Supported from Rust 1.60.0

command -v cargo >/dev/null 2>&1 || { echo >&2 "cargo is required"; exit 1; }
command -v rustup >/dev/null 2>&1 || { echo >&2 "rustup is required"; exit 1; }
command -v rustc >/dev/null 2>&1 || { echo >&2 "rustc is required"; exit 1; }

IGNORE=".cargo|/rustc|.rustup"
DIR=target
CRATES=$(cargo metadata --format-version=1 --no-deps | \
  jq -r '.workspace_members[]' | \
  cut -f3 -d" " | \
  sed 's/(path+file:\/\///g' | \
  sed 's/)//g')
eval "crates=($CRATES)"

help() {
   echo "Rust Source-based Code Coverage"
   echo
   echo "Author: @duyet <me@duyet.net>"
   echo "Usage: $0 -c|-h"
   echo
   echo "Options:"
   echo "  -c     Clean up."
   echo "  -h     Print this help."
   echo
}

init() {
  mkdir -p $DIR || true
  # Install nightly toolchain
  rustup toolchain install nightly
  # Install llvm-profdata and llvm-cov
  rustup component add llvm-tools-preview
  cargo install rustfilt
}

clean() {
  echo "Clean up previous build"
  cargo clean
  rm -rf $DIR/cov 2>/dev/null
  rm $(find . -name "*.prof*" -maxdepth 10) 2>/dev/null
  echo "Done"
}

while getopts ":hc" option; do
  case "${option}" in
      c) clean;;
      h) help; exit 0;;
      *) help; exit 1;;
  esac
done

set -x
init

# Test coverage
echo "Run test and generate profraw files"
RUSTFLAGS="-Cinstrument-coverage" \
  LLVM_PROFILE_FILE="$DIR/data-%p-%m.profraw" \
  RUSTDOCFLAGS="-Cinstrument-coverage -Zunstable-options --persist-doctests target/debug/doctestbins" \
  cargo +nightly test --message-format=json |
  grep "{" | grep "}" |
  jq -r "select(.profile.test == true) | .filenames[]" |
  grep -v dSYM - >$DIR/the-builds

# Run the profdata tool to merge them
echo "Merge profraw files into profdata"
$(rustc --print target-libdir)/../bin/llvm-profdata merge \
  $(find . -name "*.profraw" -maxdepth 10) \
  --output $DIR/default.profdata

eval "objects=($(cat $DIR/the-builds))"
mkdir -p $DIR/cov || true

$(rustc --print target-libdir)/../bin/llvm-cov report \
  --use-color \
  --ignore-filename-regex=$IGNORE \
  --instr-profile=$DIR/default.profdata \
  --summary-only \
  --Xdemangler=rustfilt \
  $(for o in "${objects[@]}" target/debug/doctestbins/*/rust_out; do [[ -x $o ]] && printf "%s %s " --object $o; done)

$(rustc --print target-libdir)/../bin/llvm-cov show \
  --format html \
  --use-color \
  --ignore-filename-regex=$IGNORE \
  --instr-profile=$DIR/default.profdata \
  --Xdemangler=rustfilt \
  --output-dir=$DIR/cov \
  --show-line-counts-or-regions \
  --show-instantiations \
  $(for o in "${objects[@]}" target/debug/doctestbins/*/rust_out; do [[ -x $o ]] && printf "%s %s " --object $o || 1; done)

open $DIR/cov/index.html || echo "Open $DIR/cov/index.html"
