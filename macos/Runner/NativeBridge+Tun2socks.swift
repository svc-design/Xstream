import Foundation
import FlutterMacOS

fileprivate let startTun2socksScript = """#!/bin/bash

# \u5b89\u88c5\u5e76\u52a0\u8f7d launchd \u670d\u52a1
set -e

SCRIPT_DIR=\"$(cd \"$(dirname \"$0\")\" && pwd)\"
PLIST=\"/Library/LaunchDaemons/com.xstream.tun2socks.plist\"

cat > \"$PLIST\" <<PLIST
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
  <key>Label</key>
  <string>com.xstream.tun2socks</string>
  <key>ProgramArguments</key>
  <array>
    <string>${SCRIPT_DIR}/tun2socks_service.sh</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
PLIST

chown root:wheel \"$PLIST\"
chmod 644 \"$PLIST\"
launchctl load -w \"$PLIST\"

echo \"tun2socks service loaded\"
"""

fileprivate let stopTun2socksScript = """#!/bin/bash

# \u5378\u8f7d launchd \u670d\u52a1\u5e76\u6e05\u7406\u8def\u7531
set -e

PLIST=\"/Library/LaunchDaemons/com.xstream.tun2socks.plist\"
TUN_DEV=\"utun123\"

launchctl unload -w \"$PLIST\" 2>/dev/null || true
rm -f \"$PLIST\" || true

ifconfig \"$TUN_DEV\" down 2>/dev/null || true
for net in 1.0.0.0/8 2.0.0.0/7 4.0.0.0/6 8.0.0.0/5 \
           16.0.0.0/4 32.0.0.0/3 64.0.0.0/2 128.0.0.0/1 \
           198.18.0.0/15; do
  route delete -net \"$net\" 2>/dev/null || true
done
killall tun2socks 2>/dev/null || true

echo \"tun2socks service unloaded\"
"""

fileprivate let serviceScript = """#!/bin/bash

# Service script executed via launchd to run tun2socks and configure routing
PROXY=\"socks5://127.0.0.1:1080\"
TUN_DEV=\"utun123\"
TUN_IP=\"198.18.0.1\"
IFACE=\"en0\"

ifconfig \"$TUN_DEV\" \"$TUN_IP\" \"$TUN_IP\" up

for net in 1.0.0.0/8 2.0.0.0/7 4.0.0.0/6 8.0.0.0/5 \
           16.0.0.0/4 32.0.0.0/3 64.0.0.0/2 128.0.0.0/1 \
           198.18.0.0/15; do
  route add -net \"$net\" \"$TUN_IP\"
done

exec tun2socks -device \"$TUN_DEV\" -proxy \"$PROXY\" -interface \"$IFACE\"
"""

extension AppDelegate {
  func handleTun2socks(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let password = args["password"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing password", details: nil))
      return
    }

    switch call.method {
    case "startTun2socks":
      runStartTun2socks(password: password, result: result)
    case "stopTun2socks":
      runStopTun2socks(password: password, result: result)
    case "installTun2socksScripts":
      runInstallTun2socksScripts(password: password, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func runStartTun2socks(password: String, result: @escaping FlutterResult) {
    let script = "/opt/homebrew/bin/start_tun2socks.sh"
    let shell = "echo \"\(password)\" | sudo -S bash \"\(script)\""

    runShellScript(command: shell, returnsBool: false, result: result)
  }

  private func runStopTun2socks(password: String, result: @escaping FlutterResult) {
    let script = "/opt/homebrew/bin/stop_tun2socks.sh"
    let shell = "echo \"\(password)\" | sudo -S bash \"\(script)\""

    runShellScript(command: shell, returnsBool: false, result: result)
  }

  private func runInstallTun2socksScripts(password: String, result: @escaping FlutterResult) {
    let startData = startTun2socksScript.data(using: .utf8)!.base64EncodedString()
    let stopData = stopTun2socksScript.data(using: .utf8)!.base64EncodedString()
    let serviceData = serviceScript.data(using: .utf8)!.base64EncodedString()

    let shell = """
echo \"\(password)\" | sudo -S bash -c 'install_dir=/opt/homebrew/bin
mkdir -p "$install_dir"
echo \"\(startData)\" | base64 -D > "$install_dir/start_tun2socks.sh"
echo \"\(stopData)\" | base64 -D > "$install_dir/stop_tun2socks.sh"
echo \"\(serviceData)\" | base64 -D > "$install_dir/tun2socks_service.sh"
chmod +x "$install_dir/start_tun2socks.sh" "$install_dir/stop_tun2socks.sh" "$install_dir/tun2socks_service.sh"'
"""

    runShellScript(command: shell, returnsBool: false, result: result)
  }
}
