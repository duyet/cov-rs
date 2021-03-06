#!/bin/bash
# Rust Source-based Code Coverage for workspaces
# Author: Duyet Le <me@duyet.net>
# Ref: https://doc.rust-lang.org/stable/rustc/instrument-coverage.html
# Supported from Rust 1.60.0

install() {
  NAME=$1
  echo "Installing $NAME ..."

  if [[ $(which yum) ]]; then
    yum install $NAME
  elif [[ $(which apt-get) ]]; then
    apt-get install -y $NAME
  elif [[ $(which apt) ]]; then
    apt install -y $NAME
  elif [[ $(which brew) ]]; then
    brew install $NAME
  else
     echo "error can't install package $NAME"
     exit 1;
  fi
}

command -v cargo >/dev/null 2>&1 || { echo >&2 "cargo is required"; exit 1; }
command -v rustup >/dev/null 2>&1 || { echo >&2 "rustup is required"; exit 1; }
command -v rustc >/dev/null 2>&1 || { echo >&2 "rustc is required"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required"; install jq; }

IGNORE=".cargo|/rustc|.rustup|target"
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
  --project-title "$PROJECT_TITLE" \
  --use-color \
  --ignore-filename-regex=$IGNORE \
  --instr-profile=$DIR/default.profdata \
  --Xdemangler=rustfilt \
  --output-dir=$DIR/cov \
  --show-line-counts-or-regions \
  --show-instantiations \
  $(for o in "${objects[@]}" target/debug/doctestbins/*/rust_out; do [[ -x $o ]] && printf "%s %s " --object $o; done)

open $DIR/cov/index.html || echo "Open $DIR/cov/index.html"

# If is in Github pull request, comment
if [ -n "${GITHUB_HEAD_REF}" ]; then
  echo "Comment on pull request"
  curl -s -X POST \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"body\": \"$(sed -r 's/^<!doctype html>//' $DIR/cov/index.html)\"}" \
    https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${GITHUB_PULL_REQUEST}/comments
fi
