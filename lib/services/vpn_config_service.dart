// lib/services/vpn_config_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/global_config.dart';
import '../utils/native_bridge.dart';
import '../templates/xray_config_template.dart';
import '../templates/xray_service_macos_template.dart';
import '../templates/xray_service_linux_template.dart';
import '../templates/xray_service_windows_template.dart';
import '../templates/tun2socks_service_macos_template.dart';

class VpnNode {
  String name;
  String countryCode;
  String configPath;
  /// Cross-platform service identifier
  ///
  /// - macOS: LaunchAgent plist file name
  /// - Linux: systemd service name
  /// - Windows: SC service name
  String serviceName;
  bool enabled;

  VpnNode({
    required this.name,
    required this.countryCode,
    required this.configPath,
    required this.serviceName,
    this.enabled = true,
  });

  factory VpnNode.fromJson(Map<String, dynamic> json) {
    return VpnNode(
      name: json['name'],
      countryCode: json['countryCode'],
      configPath: json['configPath'],
      serviceName: json['serviceName'] ?? json['plistName'],
      enabled: json['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'countryCode': countryCode,
      'configPath': configPath,
      'serviceName': serviceName,
      'enabled': enabled,
    };
  }
}

class VpnConfig {
  static List<VpnNode> _nodes = [];

  static Future<String> getConfigPath() async {
    return await GlobalApplicationConfig.getLocalConfigPath();
  }

  static Future<void> load() async {
    List<VpnNode> fromLocal = [];

    try {
      final path = await GlobalApplicationConfig.getLocalConfigPath();
      final file = File(path);
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonStr);
        fromLocal = jsonList.map((e) => VpnNode.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load local vpn_nodes.json: $e');
    }

    _nodes = fromLocal;
  }

  static List<VpnNode> get nodes => _nodes;

  static VpnNode? getNodeByName(String name) {
    try {
      return _nodes.firstWhere((e) => e.name == name);
    } catch (_) {
      return null;
    }
  }

  static void addNode(VpnNode node) {
    _nodes.add(node);
  }

  static void removeNode(String name) {
    _nodes.removeWhere((e) => e.name == name);
  }

  static void updateNode(VpnNode updated) {
    final index = _nodes.indexWhere((e) => e.name == updated.name);
    if (index != -1) {
      _nodes[index] = updated;
    }
  }

  static String exportToJson() {
    return json.encode(_nodes.map((e) => e.toJson()).toList());
  }

  static Future<String> saveToFile() async {
    final path = await GlobalApplicationConfig.getLocalConfigPath();
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(exportToJson());
    return path;
  }

  static Future<void> importFromJson(String jsonStr) async {
    final List<dynamic> jsonList = json.decode(jsonStr);
    _nodes = jsonList.map((e) => VpnNode.fromJson(e)).toList();
    await saveToFile();
  }

  static Future<void> deleteNodeFiles(VpnNode node) async {
    try {
      final jsonFile = File(node.configPath);
      if (await jsonFile.exists()) {
        await jsonFile.delete();
      }

      final servicePath =
          GlobalApplicationConfig.servicePath(node.serviceName);
      final serviceFile = File(servicePath);
      if (await serviceFile.exists()) {
        await serviceFile.delete();
      }

      removeNode(node.name);
      await saveToFile();
    } catch (e) {
      debugPrint('⚠️ 删除节点文件失败: $e');
    }
  }

  static Future<void> generateDefaultNodes({
    required String password,
    required Function(String) setMessage,
    required Function(String) logMessage,
  }) async {
    final bundleId = await GlobalApplicationConfig.getBundleId();

    const port = '1443';
    const uuid = '18d270a9-533d-4b13-b3f1-e7f55540a9b2';
    const nodes = [
      {'name': 'Global-Node', 'domain': 'trial-connector.onwalk.net'},
    ];

    for (final node in nodes) {
      await generateContent(
        nodeName: node['name']!,
        domain: node['domain']!,
        port: port,
        uuid: uuid,
        password: password,
        bundleId: bundleId,
        setMessage: setMessage,
        logMessage: logMessage,
      );
    }
  }

  static Future<void> generateContent({
    required String nodeName,
    required String domain,
    required String port,
    required String uuid,
    required String password,
    required String bundleId,
    required Function(String) setMessage,
    required Function(String) logMessage,
  }) async {
    final code = nodeName.split('-').first.toLowerCase();
    final prefix = GlobalApplicationConfig.xrayConfigPath;
    final xrayConfigPath = '${prefix}xray-vpn-node-$code.json';

    final xrayConfigContent = await _generateXrayJsonConfig(domain, port, uuid, setMessage, logMessage);
    if (xrayConfigContent.isEmpty) return;

    final serviceName = await GlobalApplicationConfig.serviceNameForRegion(code);
    final servicePath = GlobalApplicationConfig.servicePath(serviceName);

    final serviceContent = _generateServiceContent(
      code,
      bundleId,
      xrayConfigPath,
      serviceName,
    );
    if (serviceContent.isEmpty) return;

    final vpnNodesConfigPath = await GlobalApplicationConfig.getLocalConfigPath();
    final vpnNodesConfigContent = await _generateVpnNodesJsonContent(
      nodeName,
      code,
      serviceName,
      xrayConfigPath,
      setMessage,
      logMessage,
    );

    try {
      await NativeBridge.writeConfigFiles(
        xrayConfigPath: xrayConfigPath,
        xrayConfigContent: xrayConfigContent,
        servicePath: servicePath,
        serviceContent: serviceContent,
        vpnNodesConfigPath: vpnNodesConfigPath,
        vpnNodesConfigContent: vpnNodesConfigContent,
        password: password,
      );

      setMessage('✅ 配置已保存: $xrayConfigPath');
      setMessage('✅ 服务项已生成: $servicePath');
      setMessage('✅ 菜单项已更新: $vpnNodesConfigPath');
      logMessage('配置已成功保存并生成');
    } catch (e) {
      setMessage('生成配置失败: $e');
      logMessage('生成配置失败: $e');
    }
  }

  static Future<String> _generateXrayJsonConfig(String domain, String port, String uuid, Function(String) setMessage, Function(String) logMessage) async {
    try {
      final replaced = defaultXrayJsonTemplate
          .replaceAll('<SERVER_DOMAIN>', domain)
          .replaceAll('<PORT>', port)
          .replaceAll('<UUID>', uuid);

      final jsonObj = jsonDecode(replaced);
        final formatted = const JsonEncoder.withIndent('  ').convert(jsonObj);
      logMessage('✅ XrayJson 配置内容生成完成');
      return formatted;
    } catch (e) {
      setMessage('❌ XrayJson 生成失败: $e');
      logMessage('XrayJson 错误: $e');
      return '';
    }
  }

  static String _generateServiceContent(
      String nodeCode, String bundleId, String configPath, String serviceName) {
    try {
      switch (Platform.operatingSystem) {
        case 'macos':
          return renderXrayPlist(
            bundleId: bundleId,
            name: nodeCode.toLowerCase(),
            configPath: configPath,
          );
        case 'linux':
          final home = Platform.environment['HOME'] ?? '~';
          final xrayPath = '$home/.local/bin/xray';
          return renderXrayService(
            xrayPath: xrayPath,
            configPath: configPath,
          );
        case 'windows':
          final xrayPath = GlobalApplicationConfig.xrayExePath;
          return renderXrayServiceWindows(
            serviceName: serviceName.replaceAll('.schtasks', ''),
            xrayPath: xrayPath,
            configPath: configPath,
          );
        default:
          return '';
      }
    } catch (e) {
      return '';
    }
  }

  static Future<String> _generateVpnNodesJsonContent(
    String nodeName,
    String nodeCode,
    String serviceName,
    String xrayConfigPath,
    Function(String) setMessage,
    Function(String) logMessage,
  ) async {
    if (nodeName.trim().isEmpty || nodeCode.trim().isEmpty || serviceName.trim().isEmpty || xrayConfigPath.trim().isEmpty) {
        const err = '节点信息不完整，无法生成 JSON 配置';
      setMessage('❌ $err');
      logMessage(err);
      return '';
    }

    final vpnNode = {
      'name': nodeName,
      'countryCode': nodeCode,
      'serviceName': serviceName,
      'configPath': xrayConfigPath,
      'enabled': true,
    };

    final vpnNodesJsonContent = json.encode([vpnNode]);
    logMessage('✅ vpn_nodes.json 内容生成完成');
    return vpnNodesJsonContent;
  }
}

class Tun2socksService {
  static Future<String> initScripts(String password) async {
    switch (Platform.operatingSystem) {
      case 'macos':
        final content = renderTun2socksPlist(scriptDir: '/opt/homebrew/bin');
        await NativeBridge.installTun2socksScripts(password);
        return await NativeBridge.installTun2socksPlist(content, password);
      default:
        return '当前平台暂不支持';
    }
  }

  static Future<String> start(String password) async {
    switch (Platform.operatingSystem) {
      case 'macos':
        return await NativeBridge.startTun2socks(password);
      case 'linux':
      case 'windows':
      case 'android':
      case 'ios':
        return '暂未实现';
      default:
        return '当前平台暂不支持';
    }
  }

  static Future<String> stop(String password) async {
    switch (Platform.operatingSystem) {
      case 'macos':
        return await NativeBridge.stopTun2socks(password);
      case 'linux':
      case 'windows':
      case 'android':
      case 'ios':
        return '暂未实现';
      default:
        return '当前平台暂不支持';
    }
  }
}
