import Foundation
import FlutterMacOS


extension AppDelegate {
  func handleTun2socks(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let password = args["password"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing password", details: nil))
      return
    }

    guard let resourcePath = Bundle.main.resourcePath else {
      result("resource path unavailable")
      return
    }
    switch call.method {
    case "startTun2socks":
      runStartTun2socks(password: password, resourcePath: resourcePath, result: result)
    case "stopTun2socks":
      runStopTun2socks(password: password, resourcePath: resourcePath, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func runStartTun2socks(password: String, resourcePath: String, result: @escaping FlutterResult) {
    let script = "\(resourcePath)/tun2socks/start_tun2socks.sh"
    let shell = "echo \"\(password)\" | sudo -S bash \"\(script)\""

    runShellScript(command: shell, returnsBool: false, result: result)
  }

  private func runStopTun2socks(password: String, resourcePath: String, result: @escaping FlutterResult) {
    let script = "\(resourcePath)/tun2socks/stop_tun2socks.sh"
    let shell = "echo \"\(password)\" | sudo -S bash \"\(script)\""

    runShellScript(command: shell, returnsBool: false, result: result)
  }
}
