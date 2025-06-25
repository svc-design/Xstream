# Xray Core 管理设计

本文档描述 XStream 在桌面平台（macOS、Windows、Linux）上如何初始化并更新 xray-core，并生成默认节点以及同步配置到系统服务。

## 初始化与更新流程

1. **初始化 Xray**
   - 调用 `NativeBridge.initXray()` 将内置的核心文件复制到系统目录。
2. **更新 Xray Core**
   - 通过 `NativeBridge.updateXrayCore()` 下载并覆盖最新版本，下载状态可由 `isXrayDownloading()` 监控。
3. **生成默认节点**
   - `VpnConfig.generateDefaultNodes()` 根据模板创建 US、CA、JP 三个示例节点，同时写入对应的服务文件和 `vpn_nodes.json`。
4. **同步配置**
   - 在 Home 页面点击“同步配置”执行 `_reloadNodes()`，将选择的节点配置写入系统服务文件。

## 一键初始化实现

`lib/screens/settings_screen.dart` 中的 `_onInitXray()` 调整为顺序执行以上步骤：

```dart
logConsoleKey.currentState?.addLog('开始初始化 Xray...');
final init = await NativeBridge.initXray();
logConsoleKey.currentState?.addLog(init);
logConsoleKey.currentState?.addLog('开始更新 Xray Core...');
final upd = await NativeBridge.updateXrayCore();
logConsoleKey.currentState?.addLog(upd);
if (upd.startsWith('info:')) {
  GlobalState.xrayUpdating.value = true;
  await _waitForDownload();
}
logConsoleKey.currentState?.addLog('生成默认节点...');
await VpnConfig.generateDefaultNodes(
  password: GlobalState.sudoPassword.value,
  setMessage: (m) => logConsoleKey.currentState?.addLog(m),
  logMessage: (m) => logConsoleKey.currentState?.addLog(m),
);
```

完成后即可在 Home 页面同步配置并启动服务。该流程便于新用户快速准备好可用环境。
