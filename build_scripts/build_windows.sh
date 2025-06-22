#!/usr/bin/env bash
set -e
DIR="$(dirname "$0")/.."
cd "$DIR/go_core"

# Always enable CGO for cross-compiling with mingw-w64
export CGO_ENABLED=1

export CC=x86_64-w64-mingw32-gcc
GOOS=windows GOARCH=amd64 CGO_ENABLED=1 go build -buildmode=c-shared \
  -ldflags="-linkmode external -extldflags '-static'" \
  -o ../bindings/libgo_native_bridge.dll
