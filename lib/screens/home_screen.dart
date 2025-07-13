// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../../utils/native_bridge.dart';
import '../../utils/global_config.dart';
import '../../services/vpn_config_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeNode = '';
  List<VpnNode> vpnNodes = [];
  final Set<String> _selectedNodeNames = {};
  bool _isLoading = false;

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
    setState(() => _isLoading = true);
    await VpnConfig.load();
    if (!mounted) return;
    setState(() {
      vpnNodes = VpnConfig.nodes;
      _isLoading = false;
    });
  }

  Future<void> _reloadNodes() async {
    setState(() => _isLoading = true);
    await VpnConfig.load();
    if (!mounted) return;
    setState(() {
      vpnNodes = VpnConfig.nodes;
      _isLoading = false;
    });
  }

  Future<void> _toggleNode(VpnNode node) async {
    final nodeName = node.name.trim();
    if (nodeName.isEmpty) return;

    setState(() => _isLoading = true);

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
        _showMessage('⚠️ 服务已在运行');
        setState(() => _isLoading = false);
        return;
      }

      final msg = await NativeBridge.startNodeService(nodeName);
      if (!mounted) return;
      setState(() => _activeNode = nodeName);
      _showMessage(msg);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteSelectedNodes() async {
    setState(() => _isLoading = true);

    final toDelete = vpnNodes.where((e) => _selectedNodeNames.contains(e.name)).toList();
    for (final node in toDelete) {
      await VpnConfig.deleteNodeFiles(node);
    }
    _selectedNodeNames.clear();
    await _reloadNodes();
    if (!mounted) return;

    _showMessage('✅ 已删除 ${toDelete.length} 个节点并更新配置');

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobalState.isUnlocked,
      builder: (context, isUnlocked, _) {
        final content = vpnNodes.isEmpty
            ? const Center(child: Text('暂无加速节点，请先添加。'))
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

        return content;
      },
    );
  }
}
