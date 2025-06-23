# Xstream Agents

本文件描述了 Xstream 加速组件在不同平台、架构、版本下的支持能力与部署要求。

---

## Supported Platforms

| Agent Name  | OS           | Architecture | Version | Maintainer |
| ------------ | ------------ | ------------ | ------- | ---------- |
| xstream-core | macOS        | arm64, amd64 | v1.0.x  | Xstream Team |
| xstream-core | Windows      | amd64        | v1.0.x  | Xstream Team |
| xstream-core | Linux        | amd64, arm64 | v1.0.x  | Xstream Team |
| xstream-core | Android      | arm64        | v1.0.x  | Xstream Team |
| xstream-core | iOS          | arm64        | v1.0.x  | Xstream Team |

---

## Agent Capabilities Codex

| Capability   | Supported | Notes                            |
| ------------ | --------- | --------------------------------|
| HTTP Proxy   | ✅        | Full HTTP/1.1 & HTTP/2           |
| SOCKS Proxy  | ✅        | SOCKS5 support                   |
| VLESS        | ✅        | Xray VLESS Protocol              |
| TLS          | ✅        | XTLS Vision, TLS 1.3             |
| Xray Routing | ✅        | Full Routing Rules               |
| Sniffing     | ✅        | Domain, TLS, HTTP Headers        |
| GeoIP / CNIP | ✅        | IP Database Based                |
| Multi-Profile| ✅        | 支持多配置切换                    |
| PAC/Auto Mode| ✅        | 自动加速模式                     |
| Native Tray  | ✅        | 平台原生托盘图标支持             |
| Auto Update  | ✅        | 自动升级（实验性）               |
| Logging      | ✅        | 全局及单任务日志                 |

---

## Deployment Requirements

| OS      | Minimum Requirements                     | Deployment Mode                 |
| ------- | ---------------------------------------- | ------------------------------- |
| macOS   | macOS 12+                                | App Bundle / DMG                |
| Windows | Windows 10+                              | EXE Installer / MSI             |
| Linux   | Kernel 4.15+                             | tar.gz Package / Systemd Service|
| Android | Android 8.0 (API 26)+                    | APK / AAB                       |
| iOS     | iOS 14+                                  | IPA (App Store)                 |

**Build Toolchains**

- Flutter SDK 3.x with Dart ">=3.0.0 <4.0.0" (see `pubspec.yaml`)
- Go 1.20+ for native bridge compilation

---

## Configuration Schema

所有配置遵循内部模板生成系统：

- 内嵌 Xray JSON 模板
- 支持动态端口绑定
- 默认嵌入 GeoIP/GeoSite 数据库
- 配置存储目录:
  - macOS: `~/Library/Application Support/Xstream/`
  - Windows: `%APPDATA%\Xstream\`
  - Linux: `~/.config/xstream/`
  - Android: `/data/data/com.xstream/files/`
  - iOS: `~/Library/Application Support/Xstream/`

---

## Known Limitations

- 当前无 ARM Windows 版本支持
- GPU Acceleration: ❌（预留未来版本支持 QUIC & TLS offload）
- 多路复用: 受限于 Xray 内部 Mux 协议特性
- 不支持 IPv6-only 场景（部分模式已实验性支持）

---

## Agent Lifecycle Management

| Feature         | Status |
| --------------- | ------ |
| Auto Restart    | ✅     |
| Crash Recovery  | ✅     |
| Telemetry       | ❌ (本地日志，暂无远程收集) |
| Secure Update   | ✅ (签名验证机制) |
| Config Encryption| ✅ (本地加密存储) |

---

## Maintainer Notes

- 所有平台版本通过统一 CI/CD 自动构建产出
- Release 工程统一产出：
  - macOS: `.dmg`
  - Windows: `.exe` / `.msi`
  - Linux: `.tar.gz`
  - Android: `.apk` / `.aab`
  - iOS: `.ipa`
- 跨平台核心逻辑通过 Go 静态编译 & C-ABI 桥接 FFI

