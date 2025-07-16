// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../../utils/native_bridge.dart';
import '../../utils/global_config.dart' show GlobalState;
import '../../utils/app_logger.dart';
import '../l10n/app_localizations.dart';
import '../../services/vpn_config_service.dart';
import '../widgets/log_console.dart' show LogLevel;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeNode = '';
  List<VpnNode> vpnNodes = [];
  final Set<String> _selectedNodeNames = {};

  void _showMessage(String msg, {Color? bgColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bgColor),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeConfig();
  }

  Future<void> _initializeConfig() async {
    await VpnConfig.load();
    if (!mounted) return;
    setState(() {
      vpnNodes = VpnConfig.nodes;
    });
  }


  Future<void> _toggleNode(VpnNode node) async {
    final nodeName = node.name.trim();
    if (nodeName.isEmpty) return;

    // start or stop node service

    if (_activeNode == nodeName) {
      final msg = await NativeBridge.stopNodeService(nodeName);
      if (!mounted) return;
      setState(() => _activeNode = '');
      _showMessage(msg);
    } else {
      if (_activeNode.isNotEmpty) {
        await NativeBridge.stopNodeService(_activeNode);
        if (!mounted) return;
      }

      final isRunning = await NativeBridge.checkNodeStatus(nodeName);
      if (!mounted) return;
      if (isRunning) {
        setState(() => _activeNode = nodeName);
        _showMessage(context.l10n.get('serviceRunning'));
        return;
      }

      final msg = await NativeBridge.startNodeService(nodeName);
      if (!mounted) return;
      setState(() => _activeNode = nodeName);
      _showMessage(msg);
    }

  }

  void _onSyncConfig() async {
    addAppLog('开始同步配置...');
    try {
      await VpnConfig.load();
      addAppLog('✅ 已同步配置文件');
      if (!mounted) return;
      setState(() {
        vpnNodes = VpnConfig.nodes;
      });
    } catch (e) {
      addAppLog('[错误] 同步失败: $e', level: LogLevel.error);
    }
  }

  void _onDeleteConfig() async {
    final isUnlocked = GlobalState.isUnlocked.value;
    if (!isUnlocked) {
      addAppLog('请先解锁以删除配置', level: LogLevel.warning);
      return;
    }

    addAppLog('开始删除配置...');
    try {
      final nodes = List<VpnNode>.from(VpnConfig.nodes);
      for (final node in nodes) {
        await VpnConfig.deleteNodeFiles(node);
      }
      await VpnConfig.load();
      addAppLog('✅ 已删除 ${nodes.length} 个节点并更新配置');
      if (!mounted) return;
      setState(() {
        vpnNodes = VpnConfig.nodes;
        _selectedNodeNames.clear();
        _activeNode = '';
      });
    } catch (e) {
      addAppLog('[错误] 删除失败: $e', level: LogLevel.error);
    }
  }

  void _onSaveConfig() async {
    addAppLog('开始保存配置...');
    try {
      final path = await VpnConfig.getConfigPath();
      await VpnConfig.saveToFile();
      addAppLog('✅ 配置已保存到: $path');
    } catch (e) {
      addAppLog('[错误] 保存失败: $e', level: LogLevel.error);
    }
  }


  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobalState.isUnlocked,
      builder: (context, isUnlocked, _) {
        final content = vpnNodes.isEmpty
            ? Center(child: Text(context.l10n.get('noNodes')))
            : ListView.builder(
                itemCount: vpnNodes.length,
                itemBuilder: (context, index) {
                  final node = vpnNodes[index];
                  final isActive = _activeNode == node.name;
                  final isSelected = _selectedNodeNames.contains(node.name);
                  return ListTile(
                    title: Text('${node.countryCode.toUpperCase()} | ${node.name}'),
                    subtitle: const Text('VLESS | tcp'),
                    leading: isUnlocked
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedNodeNames.add(node.name);
                                } else {
                                  _selectedNodeNames.remove(node.name);
                                }
                              });
                            },
                          )
                        : null,
                    trailing: IconButton(
                      icon: Icon(
                        isActive ? Icons.stop_circle : Icons.play_circle_fill,
                        color: isActive ? Colors.red : Colors.green,
                      ),
                      onPressed: isUnlocked ? () => _toggleNode(node) : null,
                    ),
                  );
                },
              );

        return Stack(
          children: [
            content,
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: "sync",
                    onPressed: isUnlocked ? _onSyncConfig : null,
                    tooltip: context.l10n.get('syncConfig'),
                    child: const Icon(Icons.sync),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: "save",
                    onPressed: _onSaveConfig,
                    tooltip: context.l10n.get('saveConfig'),
                    child: const Icon(Icons.save),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: "delete",
                    onPressed: isUnlocked ? _onDeleteConfig : null,
                    tooltip: context.l10n.get('deleteConfig'),
                    backgroundColor: Colors.red[400],
                    child: const Icon(Icons.delete_forever),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
