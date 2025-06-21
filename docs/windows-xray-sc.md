# 在 Windows 上通过 sc 管理 Xray 服务

本文档介绍如何在 Windows 系统中使用 `sc` 命令创建并管理 Xray-core 服务，使其能够随系统启动并支持配置更新后重启。

## 准备工作

1. 确保 `xray.exe` 已复制到 `C:\Program Files\Xstream` 目录。可以在 XStream 应用中执行 `InitXray` 操作，或手动将文件放置到该目录。
2. 准备好 Xray 配置文件，例如 `C:\Program Files\Xstream\xray-config.json`。

## 创建服务

以管理员身份打开 PowerShell 或命令提示符，执行以下命令注册服务并设置开机自启：

```powershell
sc create xray-core binPath= "C:\Program Files\Xstream\xray.exe run -c C:\Program Files\Xstream\xray-config.json" start= auto
```

- `xray-core` 为服务名称，可根据需要修改。
- `start= auto` 表示系统启动时自动启动该服务。

## 启动与停止服务

```powershell
sc start xray-core   # 启动服务
sc stop xray-core    # 停止服务
```

也可以在 `services.msc` 管理界面中找到同名服务进行操作。

## 更新配置并重启

修改配置文件后，重新启动服务使改动生效：

```powershell
sc stop xray-core
sc start xray-core
```

或在 `services.msc` 中选择“重新启动”。

## 删除服务

若不再需要，可通过以下命令移除服务：

```powershell
sc delete xray-core
```
