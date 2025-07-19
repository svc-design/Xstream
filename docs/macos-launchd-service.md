# macOS tun2socks launchd 服务

本文件说明如何在 macOS 上将 `tun2socks` 作为 launchd 服务运行，实现系统开机自启动与路由自动配置。

## 启动脚本

以下脚本 `start_tun2socks.sh` 会生成 `com.xstream.tun2socks.plist` 并加载服务：

```bash
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
```

## 停止脚本

对应的 `stop_tun2socks.sh` 用于卸载服务并清理路由：

```bash
#!/bin/bash

# 卸载 launchd 服务并清理路由
set -e

PLIST="/Library/LaunchDaemons/com.xstream.tun2socks.plist"
TUN_DEV="utun123"

launchctl unload -w "$PLIST" 2>/dev/null || true
rm -f "$PLIST" || true

ifconfig "$TUN_DEV" down 2>/dev/null || true
for net in 1.0.0.0/8 2.0.0.0/7 4.0.0.0/6 8.0.0.0/5 \
           16.0.0.0/4 32.0.0.0/3 64.0.0.0/2 128.0.0.0/1 \
           198.18.0.0/15; do
  route delete -net "$net" 2>/dev/null || true
done
killall tun2socks 2>/dev/null || true

echo "tun2socks service unloaded"
```

将以上两个脚本放置在 `/opt/homebrew/bin/` 目录下后，执行 `sudo bash start_tun2socks.sh` 即可安装并启动服务，重启后也会自动运行。若需手动停止或禁用开机启动，运行 `sudo bash stop_tun2socks.sh`。
