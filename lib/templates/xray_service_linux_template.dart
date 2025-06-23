// lib/templates/xray_service_template.dart

const String defaultXrayServiceTemplate = r'''[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=<XRAY_PATH> run -c <CONFIG_PATH>
Restart=on-failure

[Install]
WantedBy=default.target
''';

String renderXrayService({
  required String xrayPath,
  required String configPath,
}) {
  return defaultXrayServiceTemplate
      .replaceAll('<XRAY_PATH>', xrayPath)
      .replaceAll('<CONFIG_PATH>', configPath);
}
