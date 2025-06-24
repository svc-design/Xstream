#!/usr/bin/env bash
set -e
DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_DIR="$DIR/build/xray-src"
OUTPUT_DIR="$DIR/ios/Frameworks"

if [ ! -d "$REPO_DIR" ]; then
  echo ">>> Cloning xray-core..."
  git clone --depth=1 https://github.com/XTLS/Xray-core "$REPO_DIR"
fi

cd "$REPO_DIR"

echo ">>> Fetching Go modules..."
go mod download

mkdir -p "$OUTPUT_DIR"

echo ">>> Building static library..."
CLANG=$(xcrun --sdk iphoneos --find clang)
SDK=$(xcrun --sdk iphoneos --show-sdk-path)

CGO_ENABLED=1 CC="$CLANG" \
  CGO_CFLAGS="-fembed-bitcode -isysroot $SDK" \
  CGO_LDFLAGS="-isysroot $SDK" \
  GOOS=ios GOARCH=arm64 \
  go build -tags jsoniter -buildmode=c-archive \
  -o "$OUTPUT_DIR/libxray-core.a" ./main

echo ">>> Output: $OUTPUT_DIR/libxray-core.a"
