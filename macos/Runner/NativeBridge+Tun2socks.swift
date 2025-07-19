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
    let startScript = "\(resourcePath)/tun2socks/start_tun2socks.sh"
    let stopScript = "\(resourcePath)/tun2socks/stop_tun2socks.sh"

    let scriptPath: String
    switch call.method {
    case "startTun2socks":
      scriptPath = startScript
    case "stopTun2socks":
      scriptPath = stopScript
    default:
      result(FlutterMethodNotImplemented)
      return
    }

    let cmd = "echo \"\(password)\" | sudo -S bash \"\(scriptPath)\""
    runShellScript(command: cmd, returnsBool: false, result: result)
  }
}
