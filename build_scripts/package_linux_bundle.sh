#!/usr/bin/env bash
set -e

# 基础路径
BUNDLE_DIR="build/linux/x64/release/bundle"
LIB_DIR="$BUNDLE_DIR/lib"
APPDIR="build/linux/AppDir"
APPIMAGE_DIR="build/linux/x64/release/AppImage"
OUTPUT_ZIP="$BUNDLE_DIR/xstream-linux.zip"
APPIMAGE_OUTPUT="$APPIMAGE_DIR/xstream-linux.AppImage"

echo ">>> Preparing directories..."
mkdir -p "$LIB_DIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPIMAGE_DIR"

echo ">>> Searching and copying libgo_native_bridge.so ..."
FOUND=false

# 查找并复制 libgo_native_bridge.so 到 BUNDLE_DIR/lib
while IFS= read -r sofile; do
    cp -u "$sofile" "$LIB_DIR/"
    FOUND=true
done < <(find . -name 'libgo_native_bridge.so')

if [ "$FOUND" != true ]; then
    echo "Error: libgo_native_bridge.so not found!"
    exit 1
fi

echo ">>> Packaging bundle (zip legacy mode)..."
cd "$BUNDLE_DIR"
zip -r xstream-linux.zip .
cd -

echo ">>> Preparing AppDir structure..."

# 拷贝主程序与动态库到 AppDir/usr/bin
cp "$BUNDLE_DIR/xstream" "$APPDIR/usr/bin/"
cp "$LIB_DIR/libgo_native_bridge.so" "$APPDIR/usr/bin/"

# 生成 AppRun 启动器
cat << 'EOF' > "$APPDIR/AppRun"
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")/usr/bin"
export LD_LIBRARY_PATH="$HERE:$LD_LIBRARY_PATH"
exec "$HERE/xstream" "$@"
EOF

chmod +x "$APPDIR/AppRun"

echo ">>> Downloading linuxdeploy and appimagetool if not exist..."

export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.local/bin"

if [ ! -f "$HOME/.local/bin/linuxdeploy-x86_64.AppImage" ]; then
    wget -O "$HOME/.local/bin/linuxdeploy-x86_64.AppImage" https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
    chmod +x "$HOME/.local/bin/linuxdeploy-x86_64.AppImage"
fi

if [ ! -f "$HOME/.local/bin/appimagetool-x86_64.AppImage" ]; then
    wget -O "$HOME/.local/bin/appimagetool-x86_64.AppImage" https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x "$HOME/.local/bin/appimagetool-x86_64.AppImage"
fi

echo ">>> Building AppImage..."
linuxdeploy-x86_64.AppImage --appdir "$APPDIR" --output appimage

mv ./*.AppImage "$APPIMAGE_OUTPUT"
echo ">>> AppImage build complete: $APPIMAGE_OUTPUT"
