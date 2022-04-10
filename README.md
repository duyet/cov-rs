# cov-rs
Rust Source-based Code Coverage

[![Test](https://github.com/duyet/cov-rs/actions/workflows/test.yaml/badge.svg)](https://github.com/duyet/cov-rs/actions/workflows/test.yaml)

# Usage

```bash
bash <(curl -s https://raw.githubusercontent.com/duyet/cov-rs/master/cov.sh)
```

# Github Workflows

See [.github/workflows/test.yaml](.github/workflows/test.yaml) for example

```yaml
on:
  push:
    branches: [master]
  pull_request:
    branches: [master]

jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Rust Toolchain
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable

      - name: Code Coverage
        env:
          GITHUB_PULL_REQUEST: ${{ github.event.pull_request.number }}
        run: |
          export GITHUB_PULL_REQUEST=${{ env.GITHUB_PULL_REQUEST }}
          export GITHUB_TOKEN=${{ secrets.GITHUB_TOKEN }}
          export PROJECT_TITLE="Example build on ${{ matrix.os }}"
          cd example && bash ../cov.sh
```

Set the `GITHUB_PULL_REQUEST`, `GITHUB_TOKEN` and `PROJECT_TITLE` (optional), the coverage script will comment the cov report on PR.

![](.github/cov-comment.png)
