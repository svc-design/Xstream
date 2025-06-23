// NativeBridge+XrayInit.swift

import Foundation
import FlutterMacOS

extension AppDelegate {
  func handlePerformAction(call: FlutterMethodCall, bundleId: String, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let action = args["action"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing action", details: nil))
      return
    }

    switch action {
    case "initXray":
      self.runInitXray(bundleId: bundleId, result: result)
    case "updateXrayCore":
      self.runInitXray(bundleId: bundleId, result: result)
    case "isXrayDownloading":
      result("0")
    case "resetXrayAndConfig":
      guard let password = args["password"] as? String else {
        result(FlutterError(code: "MISSING_PASSWORD", message: "缺少密码", details: nil))
        return
      }
      self.runResetXray(bundleId: bundleId, password: password, result: result)
    default:
      result(FlutterError(code: "UNKNOWN_ACTION", message: "Unsupported action", details: action))
    }
  }

  func runInitXray(bundleId: String, result: @escaping FlutterResult) {
    guard let resourcePath = Bundle.main.resourcePath else {
      result("❌ 无法获取 Resources 路径")
      return
    }

    let escapedPath = resourcePath.replacingOccurrences(of: "\"", with: "\\\"")

    var commands: [String] = []
    commands.append("HB_PREFIX=/opt/homebrew")
    commands.append("mkdir -p \"$HB_PREFIX\"")
    commands.append("mkdir -p \"$HB_PREFIX/etc\"")
    commands.append("mkdir -p \"$HB_PREFIX/bin\"")
    commands.append("mkdir -p \"$HOME/Library/LaunchAgents\"")
    commands.append("arch=$(uname -m)")
    commands.append("""
if [ "$arch" = "arm64" ]; then
  cp -f "\(escapedPath)/xray" $HB_PREFIX/bin/xray
elif [ "$arch" = "i386" ]; then
  cp -f "\(escapedPath)/xray.i386" $HB_PREFIX/bin/xray
elif [ "$arch" = "x86_64" ]; then
  cp -f "\(escapedPath)/xray.x86_64" $HB_PREFIX/bin/xray
else
  echo "Unsupported architecture: $arch"
  exit 1
fi
""")
    commands.append("chmod +x $HB_PREFIX/bin/xray")

    let commandJoined = commands.joined(separator: " ; ")
    let script = """
do shell script "\(commandJoined.replacingOccurrences(of: "\"", with: "\\\""))" with administrator privileges
"""

    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary? = nil
    _ = appleScript?.executeAndReturnError(&error)

    if let error = error {
      result("❌ AppleScript 执行失败: \(error)")
      logToFlutter("error", "Xray 初始化失败: \(error)")
    } else {
      result("✅ Xray 初始化完成")
      logToFlutter("info", "Xray 初始化完成")
    }
  }

  func runResetXray(bundleId: String, password: String, result: @escaping FlutterResult) {
  let rawShell = """
set -e
launchctl remove com.xstream.xray-node-jp || true
launchctl remove com.xstream.xray-node-ca || true
launchctl remove com.xstream.xray-node-us || true
rm -f /opt/homebrew/bin/xray
rm -rf /opt/homebrew/etc/xray-vpn-node*
rm -rf ~/Library/LaunchAgents/com.xstream.*
rm -rf ~/Library/LaunchAgents/xstream*
rm -rf ~/Library/Application\\ Support/xstream.svc.plus/*
"""

  // 转义双引号（\"）以便用于 AppleScript 中的 `do shell script`
  let escaped = rawShell
    .replacingOccurrences(of: "\\", with: "\\\\")  // 转义反斜杠
    .replacingOccurrences(of: "\"", with: "\\\"")  // 转义双引号
    .replacingOccurrences(of: "\n", with: " ; ")   // 保持每行执行

  let script = """
do shell script "\(escaped)" with administrator privileges
"""
    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary? = nil
    _ = appleScript?.executeAndReturnError(&error)

    if let error = error {
      result("❌ 重置失败: \(error)")
      logToFlutter("error", "重置失败: \(error)")
    } else {
      result("✅ 已清除配置与安装文件")
      logToFlutter("info", "重置完成")
    }
  }
}
