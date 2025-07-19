# Linux systemd 服务配置

本指南介绍如何在常见 Linux 发行版中将 Xray 注册为 systemd 服务，方便开机自启并在故障时自动重启。

## 创建服务文件

1. 将仓库中的 `assets/xray.service` 复制到 `/etc/systemd/system/xray.service`：

   ```bash
   sudo cp assets/xray.service /etc/systemd/system/xray.service
   ```

2. 如有需要，编辑该文件，修改 `ExecStart` 中的 Xray 执行路径和配置文件路径。
3. 重新加载 systemd：

   ```bash
   sudo systemctl daemon-reload
   ```

如果使用图形界面启动应用，也可以在应用中选择 “初始化 Xray”，它会执行以上步骤并复制默认配置文件到 `/etc/xray/config.json`。

## 启动并设置开机自启

```bash
sudo systemctl enable --now xray.service
```

## 查看运行日志

```bash
journalctl -u xray.service -f
```
