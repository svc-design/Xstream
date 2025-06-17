# Windows 构建指南

本项目通过 Go 和 Dart FFI 在 Windows 上实现核心功能。构建前需要先编译提供给 Flutter 的 DLL。

## 1. 安装依赖

1. 安装 [Go](https://go.dev/dl/) 1.20+ 并确保 `go` 在 `PATH` 中。
2. 安装 [Flutter](https://docs.flutter.dev/get-started/install/windows) SDK。

## 2. 编译 Go 共享库

在项目根目录执行：

```bash
bash build_scripts/build_windows.sh
```

执行脚本 `build_scripts/build_windows.sh`，脚本会利用 MinGW 工具链将 `go_core` 编译为 `bindings/libbridge.dll`供 FFI 调用使用，生成的 DLL 会被 Dart 通过 `DynamicLibrary.open` 加载。

## 3. 构建 Flutter 桌面应用

```
flutter clean
flutter pub get
flutter build windows
```

构建前请确保已执行上一步生成 `libbridge.dll`，否则应用无法加载共享库。


## 4. Release Packaging

GitHub Actions will compress the entire `build/windows/x64/runner/Release`
directory into `xstream-windows.zip` for distribution. The archive includes
`flutter_windows.dll` so the application can run on systems without Flutter
installed.
