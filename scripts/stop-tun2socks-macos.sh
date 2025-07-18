#!/bin/bash

# Script to stop tun2socks and clean routes.

TUN_DEV="utun123"

sudo ifconfig "$TUN_DEV" down

for net in 1.0.0.0/8 2.0.0.0/7 4.0.0.0/6 8.0.0.0/5 \
           16.0.0.0/4 32.0.0.0/3 64.0.0.0/2 128.0.0.0/1 \
           198.18.0.0/15; do
    sudo route delete -net "$net"
done

echo "❌ tun2socks stopped"
