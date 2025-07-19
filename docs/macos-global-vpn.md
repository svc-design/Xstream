# macOS tun2socks 全局代理指南

本文档说明如何在 macOS 上通过 [xjasonlyu/tun2socks](https://github.com/xjasonlyu/tun2socks) 配合 SOCKS5 代理接管系统流量。适用于临时在命令行中创建全局 VPN。

## 准备条件

- macOS 11 及以上，系统需支持 utun 虚拟网卡
- 可用的 SOCKS5 代理，例如 `127.0.0.1:1080`
- 已下载编译好的 `tun2socks` 可执行文件

## 步骤 1：启动 tun2socks

```bash
./tun2socks \
  -device utun123 \
  -proxy socks5://127.0.0.1:1080 \
  -interface en0 &
```

- `-device` 指定创建的 TUN 接口名称
- `-proxy` 设置代理服务器地址
- `-interface` 指向系统的实际网络接口（通常为 Wi‑Fi 或 Ethernet）

## 步骤 2：激活接口

```bash
sudo ifconfig utun123 198.18.0.1 198.18.0.1 up
```

推荐使用 `198.18.0.1` 以避免与真实网络冲突。

## 步骤 3：添加路由

```bash
sudo route add -net 1.0.0.0/8     198.18.0.1
sudo route add -net 2.0.0.0/7     198.18.0.1
sudo route add -net 4.0.0.0/6     198.18.0.1
sudo route add -net 8.0.0.0/5     198.18.0.1
sudo route add -net 16.0.0.0/4    198.18.0.1
sudo route add -net 32.0.0.0/3    198.18.0.1
sudo route add -net 64.0.0.0/2    198.18.0.1
sudo route add -net 128.0.0.0/1   198.18.0.1
sudo route add -net 198.18.0.0/15 198.18.0.1
```

上述路由将所有公网流量导向 `tun2socks`，再转发至 SOCKS5 代理。

## 一键启动脚本

仓库提供 `scripts/start-tun2socks-macos.sh` 便捷脚本，可自动完成以上步骤：

```bash
bash scripts/start-tun2socks-macos.sh
```

停止服务可执行 `scripts/stop-tun2socks-macos.sh`。

如需开机自动运行，可将脚本注册为 `launchd` 服务。应用内的 `start_tun2socks.sh`
会在 `/Library/LaunchDaemons` 生成并加载 `com.xstream.tun2socks.plist`
，停止脚本则负责卸载该服务。

在图形界面中，可通过首页右下角的模式切换按钮选择 **VPN** 或 **仅代理**。
选择 **VPN** 会触发 `tun2socks` 服务启动；选择 **仅代理** 则会停止该服务。
