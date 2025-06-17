#!/usr/bin/env bash
set -e
DIR="$(dirname "$0")/.."
cd "$DIR/go_core"

# Ensure CGO is enabled for Linux builds
if [ "$(go env CGO_ENABLED)" != "1" ]; then
  export CGO_ENABLED=1
fi

# Use the host compiler (defaults to gcc) to build the shared library
: "${CC:=gcc}"
CC=$CC GOOS=linux GOARCH=amd64 go build -buildmode=c-shared -o ../bindings/libgo_native_bridge.so

# Copy the library next to the executable so it is bundled with the app
mkdir -p ../linux/lib
cp ../bindings/libgo_native_bridge.so ../linux/lib/
