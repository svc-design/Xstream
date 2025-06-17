#!/usr/bin/env bash
set -e

# 基础目录
DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR/go_core"

# 默认目标架构
GOOS=linux
GOARCH=amd64

# 输出路径：Flutter 预期位置 & 打包预期位置
FLUTTER_LIB_DIR="$DIR/linux/lib"

# 确保输出目录都存在
mkdir -p "$FLUTTER_LIB_DIR"

# 启用CGO
export CGO_ENABLED=1

# 检测 Flutter clang 工具链
FLUTTER_BIN=$(command -v flutter || true)
if [ -n "$FLUTTER_BIN" ]; then
  FLUTTER_ROOT=$(readlink -f "$FLUTTER_BIN" | xargs dirname | xargs dirname)
  FLUTTER_ROOT=${FLUTTER_ROOT%/bin}
  CANDIDATE_CC="$FLUTTER_ROOT/usr/bin/clang"
  CANDIDATE_CXX="$FLUTTER_ROOT/usr/bin/clang++"
  if [ -x "$CANDIDATE_CC" ] && [ -x "$CANDIDATE_CXX" ]; then
    CC="$CANDIDATE_CC"
    CXX="$CANDIDATE_CXX"
  fi
fi

: "${CC:=$(command -v clang)}"
: "${CXX:=$(command -v clang++)}"

if [ -z "$CC" ] || [ -z "$CXX" ]; then
  echo "clang/clang++ are required" >&2
  exit 1
fi

export CC
export CXX

echo ">>> Building Go shared library"
CC=$CC GOOS=$GOOS GOARCH=$GOARCH go build -buildmode=c-shared -o "$FLUTTER_LIB_DIR/libgo_native_bridge.so"

echo ">>> Build complete: $FLUTTER_LIB_DIR/libgo_native_bridge.so"
