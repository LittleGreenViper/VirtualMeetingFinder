#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Prefer native Homebrew Ruby on Apple Silicon. An Intel Ruby launches
# SourceKitten under Rosetta, which cannot load Xcode's ARM-only SourceKit.
if [ -x /opt/homebrew/opt/ruby/bin/ruby ]; then
    PATH="/opt/homebrew/opt/ruby/bin:$PATH"
    export PATH
fi

STAGING_DIR="$(mktemp -d "$SCRIPT_DIR/.jazzy.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' 0
trap 'exit 130' INT
trap 'exit 143' TERM

# Load Jazzy through this Ruby, bypassing stale executable wrappers that
# may still have an Intel Ruby path in their shebang.
ruby -r rubygems -e 'load Gem.bin_path("jazzy", "jazzy")' -- \
    --output "$STAGING_DIR/docs"

mkdir -p "$STAGING_DIR/docs/img"
cp img/*.* "$STAGING_DIR/docs/img/"
cp icon.png LGV.png "$STAGING_DIR/docs/"

# Keep the existing documentation until generation and asset copying succeed.
rm -rf docs
mv "$STAGING_DIR/docs" docs
