// lib/templates/xray_plist_template.dart

const String defaultXrayPlistTemplate = r'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string><BUNDLE_ID>.xray-node-<NAME></string>
  <key>ProgramArguments</key>
  <array>
    <string>/opt/homebrew/bin/xray</string>
    <string>run</string>
    <string>-c</string>
    <string><CONFIG_PATH></string>
  </array>
  <key>StandardOutPath</key>
  <string>/tmp/xray-vpn-<NAME>-node.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/xray-vpn-<NAME>-node.err</string>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
''';

String renderXrayPlist({
  required String bundleId,
  required String name,
  required String configPath,
}) {
  return defaultXrayPlistTemplate
      .replaceAll('<BUNDLE_ID>', bundleId)
      .replaceAll('<NAME>', name)
      .replaceAll('<CONFIG_PATH>', configPath);
}
