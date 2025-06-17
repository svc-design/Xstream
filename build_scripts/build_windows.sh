#!/usr/bin/env bash
set -e
DIR="$(dirname "$0")/.."
cd "$DIR/go_core"

# Ensure CGO is enabled for cross-compiling with mingw-w64
if [ "$(go env CGO_ENABLED)" != "1" ]; then
  export CGO_ENABLED=1
fi

export CC=x86_64-w64-mingw32-gcc
GOOS=windows GOARCH=amd64 go build -buildmode=c-shared \
  -ldflags="-linkmode external -extldflags '-static'" \
  -o ../bindings/libgo_native_bridge.dll
