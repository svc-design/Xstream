# 开发者构建指南（macOS）

本指南适用于希望在 macOS 上本地构建和调试 XStream 项目的开发者。

## 环境准备

### 1. 安装 Flutter

使用 Homebrew 安装 Flutter： brew install --cask flutter

或者参考官方安装指南：Flutter 安装文档

2. 安装 Xcode 和配置

前往 App Store 或 Apple Developer 官网安装最新版 Xcode。

初次安装后运行初始化命令： sudo xcodebuild -runFirstLaunch
安装命令行工具（如果未安装）： xcode-select --install

3. 安装 CocoaPods（iOS/macOS 必需）

sudo gem install cocoapods

4. 拉取依赖并构建

flutter pub get
sh scripts/generate_icons.sh  # 生成 iOS App 图标
flutter build macos
开发调试
使用 VS Code 或 Android Studio 打开项目根目录，可执行如下命令调试：
flutter run -d macos
或使用调试按钮直接运行项目。

# 目录结构简述

lib/：Flutter 主代码目录
macos/：平台特定配置与原生代码（Swift）
assets/：图标、Xray 配置等静态资源

# 常见问题
构建失败、权限错误
检查是否正确授予 macOS 网络和文件访问权限

使用 flutter clean 清除缓存后重新构建


macos/
└── Runner/
    ├── AppDelegate.swift               # 保留主入口和 Flutter channel 注册逻辑
    ├── NativeBridge+ConfigWriter.swift # 包含 writeConfigFiles、writeFile 等配置写入相关函数
    ├── NativeBridge+XrayInit.swift     # 包含 runInitXray 的 AppleScript 权限处理与初始化逻辑
    ├── NativeBridge+ServiceControl.swift # 启动/停止/check 服务的 launchctl 相关逻辑
    └── NativeBridge+Logger.swift       # logToFlutter 日志通道封装

lib/services/update/
├── models/update_info.dart         ✅ 原 `UpdateInfo` 数据结构已迁移
├── update_platform.dart            ✅ 平台识别 + 渠道（stable/latest）支持
├── update_service.dart             ✅ 使用 Pulp REST API 查询版本
└── update_checker.dart             ✅ 定时检查 + 弹窗 UI 封装

- DMG filename now follows the pattern:
  - `xstream-release-<tag>.dmg` if tagged on main branch
  - `xstream-latest-<commit>.dmg` if untagged on main
  - `xstream-dev-<commit>.dmg` for non-main branches
