#!/bin/bash
# Rust Source-based Code Coverage for workspaces
# Author: Duyet Le <me@duyet.net>
# Ref: https://doc.rust-lang.org/stable/rustc/instrument-coverage.html
# Supported from Rust 1.60.0

set -euo pipefail

install() {
  local name=$1
  echo "Installing $name ..."

  if command -v yum >/dev/null 2>&1; then
    sudo yum install -y "$name"
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install -y "$name"
  elif command -v apt >/dev/null 2>&1; then
    sudo apt install -y "$name"
  elif command -v brew >/dev/null 2>&1; then
    brew install "$name"
  else
     echo "Error: Cannot install package '$name' - no supported package manager found" >&2
     echo "Please install $name manually" >&2
     exit 1
  fi
}

# Check required commands
command -v cargo >/dev/null 2>&1 || { echo >&2 "Error: cargo is required but not installed. Visit https://rustup.rs/"; exit 1; }
command -v rustup >/dev/null 2>&1 || { echo >&2 "Error: rustup is required but not installed. Visit https://rustup.rs/"; exit 1; }
command -v rustc >/dev/null 2>&1 || { echo >&2 "Error: rustc is required but not installed. Visit https://rustup.rs/"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required, attempting to install..."; install jq; }

IGNORE=".cargo|/rustc|.rustup|target"
DIR=target

help() {
   cat <<EOF
Rust Source-based Code Coverage

Author: @duyet <me@duyet.net>
Usage: $0 [OPTIONS]

Options:
  -c, --clean          Clean up previous coverage data
  -h, --help           Print this help message
  -t, --threshold NUM  Fail if coverage is below NUM percent (optional)

Environment Variables:
  GITHUB_PULL_REQUEST  PR number for GitHub comment
  GITHUB_TOKEN         GitHub token for API access
  GITHUB_REPOSITORY    Repository in owner/repo format
  PROJECT_TITLE        Title for the coverage report (optional)

Examples:
  $0                   Generate coverage report
  $0 -c                Clean previous coverage data
  $0 -t 80             Fail if coverage is below 80%

EOF
}

init() {
  echo "==> Initializing coverage environment..."
  mkdir -p "$DIR" || true

  # Install nightly toolchain
  if ! rustup toolchain list | grep -q nightly; then
    echo "Installing nightly toolchain..."
    rustup toolchain install nightly
  else
    echo "Nightly toolchain already installed"
  fi

  # Install llvm-tools-preview
  if ! rustup component list --toolchain nightly | grep -q "llvm-tools-preview.*installed"; then
    echo "Installing llvm-tools-preview..."
    rustup component add llvm-tools-preview --toolchain nightly
  else
    echo "llvm-tools-preview already installed"
  fi

  # Install rustfilt if not present
  if ! command -v rustfilt >/dev/null 2>&1; then
    echo "Installing rustfilt..."
    cargo install rustfilt
  else
    echo "rustfilt already installed"
  fi
}

clean() {
  echo "==> Cleaning up previous build artifacts..."
  cargo clean
  rm -rf "${DIR:?}/cov" 2>/dev/null || true
  find . -maxdepth 10 -name "*.prof*" -type f -delete 2>/dev/null || true
  echo "Done"
}

open_browser() {
  local file=$1
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$file" 2>/dev/null || echo "Coverage report: $file"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "$file" 2>/dev/null || echo "Coverage report: $file"
  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    start "$file" 2>/dev/null || echo "Coverage report: $file"
  else
    echo "Coverage report: $file"
  fi
}

# Parse command line arguments
THRESHOLD=""
while getopts ":hct:-:" option; do
  case "${option}" in
      c) clean; exit 0;;
      h) help; exit 0;;
      t) THRESHOLD="${OPTARG}";;
      -)
        case "${OPTARG}" in
          clean) clean; exit 0;;
          help) help; exit 0;;
          threshold) THRESHOLD="${!OPTIND}"; OPTIND=$((OPTIND + 1));;
          threshold=*) THRESHOLD="${OPTARG#*=}";;
          *) echo "Unknown option --${OPTARG}" >&2; help; exit 1;;
        esac
        ;;
      *) help; exit 1;;
  esac
done

init

# Get LLVM tools path
LLVM_TOOLS_DIR="$(rustc --print target-libdir)/../bin"
if [[ ! -d "$LLVM_TOOLS_DIR" ]]; then
  echo "Error: LLVM tools directory not found at $LLVM_TOOLS_DIR" >&2
  exit 1
fi

LLVM_PROFDATA="$LLVM_TOOLS_DIR/llvm-profdata"
LLVM_COV="$LLVM_TOOLS_DIR/llvm-cov"

if [[ ! -x "$LLVM_PROFDATA" ]]; then
  echo "Error: llvm-profdata not found. Install with: rustup component add llvm-tools-preview" >&2
  exit 1
fi

# Test coverage
echo "==> Running tests and generating profraw files..."
RUSTFLAGS="-Cinstrument-coverage" \
  LLVM_PROFILE_FILE="$DIR/data-%p-%m.profraw" \
  RUSTDOCFLAGS="-Cinstrument-coverage -Zunstable-options --persist-doctests target/debug/doctestbins" \
  cargo +nightly test --message-format=json 2>&1 | tee "$DIR/test-output.log" | \
  grep "{" | \
  jq -r "select(.profile.test == true) | .filenames[]" | \
  grep -v dSYM > "$DIR/the-builds" || true

if [[ ! -s "$DIR/the-builds" ]]; then
  echo "Warning: No test binaries found. Make sure your project has tests." >&2
fi

# Find all profraw files
echo "==> Merging profraw files into profdata..."
mapfile -t profraw_files < <(find . -maxdepth 10 -name "*.profraw" -type f)

if [[ ${#profraw_files[@]} -eq 0 ]]; then
  echo "Error: No profraw files found. Tests may have failed." >&2
  exit 1
fi

"$LLVM_PROFDATA" merge "${profraw_files[@]}" --output "$DIR/default.profdata"

# Read test binaries safely without eval
mapfile -t objects < "$DIR/the-builds"
mkdir -p "$DIR/cov" || true

# Build object arguments
object_args=()
for obj in "${objects[@]}"; do
  if [[ -x "$obj" ]]; then
    object_args+=(--object "$obj")
  fi
done

# Add doctest binaries
for doctest in target/debug/doctestbins/*/rust_out; do
  if [[ -x "$doctest" ]]; then
    object_args+=(--object "$doctest")
  fi
done

if [[ ${#object_args[@]} -eq 0 ]]; then
  echo "Error: No executable test binaries found" >&2
  exit 1
fi

# Generate console report
echo ""
echo "==> Coverage Report"
echo "===================="
"$LLVM_COV" report \
  --use-color \
  --ignore-filename-regex="$IGNORE" \
  --instr-profile="$DIR/default.profdata" \
  --Xdemangler=rustfilt \
  "${object_args[@]}" | tee "$DIR/coverage-summary.txt"

# Extract coverage percentage
COVERAGE_PCT=$(grep "TOTAL" "$DIR/coverage-summary.txt" | awk '{print $NF}' | sed 's/%//')

# Check threshold if specified
if [[ -n "$THRESHOLD" ]]; then
  echo ""
  if (( $(echo "$COVERAGE_PCT < $THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
    echo "❌ Coverage $COVERAGE_PCT% is below threshold $THRESHOLD%"
    exit 1
  else
    echo "✅ Coverage $COVERAGE_PCT% meets threshold $THRESHOLD%"
  fi
fi

# Generate HTML report
echo ""
echo "==> Generating HTML report..."
"$LLVM_COV" show \
  --format html \
  --project-title "${PROJECT_TITLE:-Code Coverage Report}" \
  --use-color \
  --ignore-filename-regex="$IGNORE" \
  --instr-profile="$DIR/default.profdata" \
  --Xdemangler=rustfilt \
  --output-dir="$DIR/cov" \
  --show-line-counts-or-regions \
  --show-instantiations \
  "${object_args[@]}"

echo "HTML report generated at: $DIR/cov/index.html"
open_browser "$DIR/cov/index.html"

# GitHub PR comment
if [[ -n "${GITHUB_PULL_REQUEST:-}" && -n "${GITHUB_TOKEN:-}" && -n "${GITHUB_REPOSITORY:-}" ]]; then
  echo ""
  echo "==> Posting coverage report to GitHub PR #$GITHUB_PULL_REQUEST..."

  # Create markdown comment
  COMMENT_BODY=$(cat <<COMMENT_EOF
## ${PROJECT_TITLE:-Code Coverage Report}

\`\`\`
$(cat "$DIR/coverage-summary.txt")
\`\`\`

**Total Coverage:** $COVERAGE_PCT%

📊 [View detailed HTML report]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID)
COMMENT_EOF
)

  # Post comment with retry logic
  for i in {1..4}; do
    if curl -s -f -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Content-Type: application/json" \
      -H "Accept: application/vnd.github.v3+json" \
      -d "$(jq -n --arg body "$COMMENT_BODY" '{body: $body}')" \
      "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$GITHUB_PULL_REQUEST/comments" \
      >/dev/null; then
      echo "✅ Successfully posted coverage report to PR"
      break
    else
      if [[ $i -lt 4 ]]; then
        sleep_time=$((2 ** i))
        echo "Retry $i failed, waiting ${sleep_time}s..."
        sleep $sleep_time
      else
        echo "⚠️  Failed to post comment to PR after 4 attempts" >&2
      fi
    fi
  done
fi

echo ""
echo "✅ Coverage analysis complete!"
