#!/bin/bash

# Unload launchd service and clean routes
set -e

PLIST="/Library/LaunchDaemons/com.xstream.tun2socks.plist"

launchctl unload -w "$PLIST" 2>/dev/null || true
rm -f "$PLIST" || true

TUN_DEV="utun123"

ifconfig "$TUN_DEV" down 2>/dev/null || true
for net in 1.0.0.0/8 2.0.0.0/7 4.0.0.0/6 8.0.0.0/5 \
           16.0.0.0/4 32.0.0.0/3 64.0.0.0/2 128.0.0.0/1 \
           198.18.0.0/15; do
  route delete -net "$net" 2>/dev/null || true
done
killall tun2socks 2>/dev/null || true

echo "tun2socks service unloaded"
