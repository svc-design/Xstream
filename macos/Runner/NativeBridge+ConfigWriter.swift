// NativeBridge+ConfigWriter.swift
import Foundation
import FlutterMacOS

extension AppDelegate {
  func writeConfigFiles(call: FlutterMethodCall, result: @escaping FlutterResult) {
    // 获取传递的参数
    guard let args = call.arguments as? [String: Any],
          let xrayConfigPath = args["xrayConfigPath"] as? String,
          let xrayConfigContent = args["xrayConfigContent"] as? String, // 修改这里
          let servicePath = args["servicePath"] as? String,
          let serviceContent = args["serviceContent"] as? String,
          let vpnNodesConfigPath = args["vpnNodesConfigPath"] as? String,
          let vpnNodesConfigContent = args["vpnNodesConfigContent"] as? String,
          let sudoPass = args["password"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "缺少必要的参数", details: nil))
      return
    }

    do {
      // 写入 Xray 配置文件
      try writeXrayConfig(path: xrayConfigPath, content: xrayConfigContent, password: sudoPass, result: result)
      // 写入 Plist 配置文件
      try writePlistFile(path: servicePath, content: serviceContent, password: sudoPass, result: result)
      // 更新 vpn_nodes.json 文件
      try updateVpnNodesConfig(path: vpnNodesConfigPath, content: vpnNodesConfigContent, password: sudoPass, result: result)
      // 返回成功消息
      result("Configuration files written successfully")
    } catch {
      // 捕获并返回错误
      result(FlutterError(code: "WRITE_ERROR", message: "写入失败", details: error.localizedDescription))
      logToFlutter("error", "写入失败: \(error.localizedDescription)")
    }
  }

  private func writeXrayConfig(path: String, content: String, password: String, result: @escaping FlutterResult) throws {
    logToFlutter("info", "创建 Xray 配置文件: \(path)")
    try runPrivilegedWrite(path: path, content: content, password: password, result: result)
  }

  private func writePlistFile(path: String, content: String, password: String, result: @escaping FlutterResult) throws {
    logToFlutter("info", "写入 LaunchAgent plist: \(path)")
    try runPrivilegedWrite(path: path, content: content, password: password, result: result)
  }

  private func updateVpnNodesConfig(path: String, content: String, password: String, result: @escaping FlutterResult) throws {
    logToFlutter("info", "更新 vpn_nodes.json: \(path)")
    let fileManager = FileManager.default

    // 读取现有的 vpn_nodes.json 文件内容
    var vpnNodes: [[String: Any]] = []

    if fileManager.fileExists(atPath: path) {
      let data = try Data(contentsOf: URL(fileURLWithPath: path))
      vpnNodes = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] ?? []
      logToFlutter("info", "读取成功: \(path)")
    }

    // 将新的节点数据添加到现有内容中
    if let newNodes = try? JSONSerialization.jsonObject(with: content.data(using: .utf8)!, options: []) as? [[String: Any]] {
        vpnNodes.append(contentsOf: newNodes)
    } else {
    throw NSError(domain: "vpn_nodes_json", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid content for new node"])
    }

    // 更新 vpn_nodes.json 文件
    let updatedJson = try JSONSerialization.data(withJSONObject: vpnNodes, options: .prettyPrinted)

    // 将更新后的内容写入文件
    try runPrivilegedWrite(path: path, content: String(data: updatedJson, encoding: .utf8) ?? "", password: password, result: result)
    logToFlutter("info", "vpn_nodes.json 写入成功: \(path)")
  }

  private func runPrivilegedWrite(path: String, content: String, password: String, result: @escaping FlutterResult) throws {
    let escapedContent = content.replacingOccurrences(of: "\"", with: "\\\"")
    let script = "echo \"\(password)\" | sudo -S bash -c 'echo \"\(escapedContent)\" > \"\(path)\"'"
    runShellScript(command: script, returnsBool: true, result: result)
  }
}
