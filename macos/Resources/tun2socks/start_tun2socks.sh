#!/bin/bash

# 安装并加载 launchd 服务
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST="/Library/LaunchDaemons/com.xstream.tun2socks.plist"

cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.xstream.tun2socks</string>
  <key>ProgramArguments</key>
  <array>
    <string>${SCRIPT_DIR}/tun2socks_service.sh</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
PLIST

chown root:wheel "$PLIST"
chmod 644 "$PLIST"
launchctl load -w "$PLIST"

echo "tun2socks service loaded"

