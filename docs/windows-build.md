# Windows 开发环境搭建

本指引帮助在 Windows 上完成 XStream 的编译。依赖 Go 用于生成桥接库，并需要安装编译器以支持 CGO。

## 1. 安装 Go 与 MinGW-w64

1. 安装 [Go](https://go.dev/dl/) 1.20 及以上版本，并确保 `go` 命令在 `PATH` 中。
2. 安装 MinGW-w64 工具链，可在 PowerShell 中执行：
   ```powershell
   winget install -e --id MSYS2.MSYS2
   pacman -Syu mingw-w64-x86_64-gcc
   ```
   安装完成后，确认 `gcc --version` 能正确输出版本信息。

## 2. 插件目录结构

项目在 `windows/` 下集成了一套 Go+C++ 桥接代码，主要文件如下：

```text
windows/
├── go/
│   └── nativebridge.go        # Go 导出的逻辑实现
└── runner/
    ├── native_bridge_plugin.cpp
    ├── native_bridge_plugin.h
    └── CMakeLists.txt         # 构建规则，可生成 libgo_logic.a
```

`nativebridge.go` 使用 `//export` 暴露函数供 C 调用。仓库已提供预编译的
`libgo_logic.a` 与头文件，CMake 规则仅在需要重新生成时使用。`NativeBridgePlugin`
会链接该库并通过 `MethodChannel` 与 Dart 层通信。

插件的注册逻辑节选自 `native_bridge_plugin.cpp`：

```cpp
void NativeBridgePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "com.xstream/native",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<NativeBridgePlugin>();
  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  registrar->AddPlugin(std::move(plugin));
}
```

对应的 CMake 片段会在 `windows/runner/CMakeLists.txt` 中调用 Go 构建：

```cmake
add_custom_command(
  OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/libgo_logic.a ${CMAKE_CURRENT_SOURCE_DIR}/libgo_logic.h
  COMMAND ${CMAKE_COMMAND} -E env GOOS=windows GOARCH=amd64 CGO_ENABLED=1
          ${GO_EXECUTABLE} build -buildmode=c-archive -o libgo_logic.a ./go/nativebridge.go
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DEPENDS ../go/nativebridge.go
  BYPRODUCTS ${CMAKE_CURRENT_SOURCE_DIR}/libgo_logic.h
)
```

## 3. 预编译的 Go 静态库

仓库已包含用于 Windows 的 Go 静态库，无需在本地执行 `go build`。
若遇 CGO 相关问题，可确认已安装 Go 与 MinGW-w64，并根据环境变量启用 CGO。

## 4. 构建 Flutter 桌面应用

```
flutter clean
flutter pub get
flutter build windows
```

若环境配置正确，预编译的库会在构建过程中自动链接，无需执行 Go 命令。

## 5. 调试模式

构建完成后，可在 `build/windows/x64/runner/Release` 目录下通过命令行运行

```powershell
./xstream.exe --debug
```

加入 `--debug` 参数会在控制台输出启动日志，便于排查依赖路径或权限问题。

## 6. Release Packaging

GitHub Actions will compress the entire `build/windows/x64/runner/Release`
directory into `xstream-windows.zip` for distribution. The archive includes
`flutter_windows.dll` so the application can run on systems without Flutter
installed.
