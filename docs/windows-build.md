# Windows 开发环境搭建

本指引帮助在 Windows 上完成 XStream 的编译。项目通过 Go 提供 FFI 共享库，需要安装编译器以支持 CGO。

## 1. 安装 Go 与 MinGW-w64

1. 安装 [Go](https://go.dev/dl/) 1.20 及以上版本，并确保 `go` 命令在 `PATH` 中。
2. 安装 MinGW-w64 工具链，可在 PowerShell 中执行：
   ```powershell
   winget install -e --id MSYS2.MSYS2
   pacman -Syu mingw-w64-x86_64-gcc
   ```
   安装完成后，确认 `gcc --version` 能正确输出版本信息。

## 2. 编译 Go 共享库

在项目根目录执行：

```bash
bash build_scripts/build_windows.sh
```

脚本会利用 MinGW 工具链将 `go_core` 编译为 `bindings/libbridge.dll`，供 FFI 调用使用。

## 3. 构建 Flutter 桌面应用

```
flutter clean
flutter pub get
flutter build windows
```

构建前请确保已执行上一步生成 `libbridge.dll`，否则应用无法加载共享库。

## 4. 调试模式

构建完成后，可在 `build/windows/x64/runner/Release` 目录下通过命令行运行

```powershell
./xstream.exe --debug
```

加入 `--debug` 参数会在控制台输出启动日志，便于排查依赖路径或权限问题。

## 5. Release Packaging

GitHub Actions will compress the entire `build/windows/x64/runner/Release`
directory into `xstream-windows.zip` for distribution. The archive includes
`flutter_windows.dll` so the application can run on systems without Flutter
installed.
