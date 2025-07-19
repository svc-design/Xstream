import Foundation
import FlutterMacOS

fileprivate let tun2socksPlistTemplate = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.xstream.tun2socks</string>
  <key>ProgramArguments</key>
  <array>
    <string><SCRIPT_DIR>/tun2socks_service.sh</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
"""

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
      runStopTun2socks(password: password, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func runStartTun2socks(password: String, resourcePath: String, result: @escaping FlutterResult) {
    let plistPath = "/Library/LaunchDaemons/com.xstream.tun2socks.plist"
    let scriptDir = "\(resourcePath)/tun2socks"
    let plistContent = tun2socksPlistTemplate.replacingOccurrences(of: "<SCRIPT_DIR>", with: scriptDir)
    let escaped = plistContent.replacingOccurrences(of: "\"", with: "\\\"")

    let shell = """
echo \"\(password)\" | sudo -S bash -c 'cat <<"EOF" > "\(plistPath)"
\(escaped)
EOF
chown root:wheel "\(plistPath)"
chmod 644 "\(plistPath)"
launchctl load -w "\(plistPath)"
'
"""

    runShellScript(command: shell, returnsBool: false, result: result)
  }

  private func runStopTun2socks(password: String, result: @escaping FlutterResult) {
    let plistPath = "/Library/LaunchDaemons/com.xstream.tun2socks.plist"

    let shell = """
echo \"\(password)\" | sudo -S bash -c '
launchctl unload -w "\(plistPath)" 2>/dev/null || true
rm -f "\(plistPath)" || true
ifconfig utun123 down 2>/dev/null || true
for net in 1.0.0.0/8 2.0.0.0/7 4.0.0.0/6 8.0.0.0/5 \
           16.0.0.0/4 32.0.0.0/3 64.0.0.0/2 128.0.0.0/1 \
           198.18.0.0/15; do
  route delete -net "$net" 2>/dev/null || true
done
killall tun2socks 2>/dev/null || true
'
"""

    runShellScript(command: shell, returnsBool: false, result: result)
  }
}
