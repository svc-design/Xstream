# macOS tun2socks launchd 服务

本文件说明如何在 macOS 上将 `tun2socks` 作为 launchd 服务运行，实现系统开机自启动与路由自动配置。

## 启动脚本

以下脚本 `start_tun2socks.sh` 负责启动 `tun2socks` 并配置路由：

```bash
#!/bin/bash

set -e

TUN_DEV="utun123"
TUN_IP="198.18.0.1"
ROUTES=("0.0.0.0/1" "128.0.0.0/1")
EXCLUDE=("10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16")

GW_IF=$(route get 8.8.8.8 | awk '/interface: /{print $2}')

sudo nohup /opt/homebrew/bin/tun2socks \
  -device "$TUN_DEV" \
  -proxy socks5://127.0.0.1:1080 \
  -interface "$GW_IF" \
  > /tmp/log 2>&1 &

sleep 1

sudo ifconfig "$TUN_DEV" inet "$TUN_IP" "$TUN_IP" netmask 255.255.255.0 up

for net in "${ROUTES[@]}"; do
  sudo route -n add -net "$net" -interface "$TUN_DEV"
done

for net in "${EXCLUDE[@]}"; do
  sudo route -n delete -net "$net" 2>/dev/null || true
done

echo "✅ tun2socks 启动完成，流量已劫持到 $TUN_DEV"
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

ifconfig "$TUN_DEV" down 2>/dev/null || true
for net in 1.0.0.0/8 2.0.0.0/7 4.0.0.0/6 8.0.0.0/5 \
           16.0.0.0/4 32.0.0.0/3 64.0.0.0/2 128.0.0.0/1 \
           198.18.0.0/15; do
  route delete -net "$net" 2>/dev/null || true
done
killall tun2socks 2>/dev/null || true

echo "tun2socks service unloaded"
```

将脚本放置在 `/opt/homebrew/bin/` 后，可配合由设置页生成的 `com.xstream.tun2socks.plist` 通过 `launchctl load` 启动，停止时运行 `sudo bash stop_tun2socks.sh` 清理路由。
