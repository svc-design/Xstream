// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../../utils/native_bridge.dart';
import '../../utils/global_config.dart';
import '../../services/vpn_config_service.dart';
import '../../services/cloud_sync_service.dart';

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

  Future<void> _uploadToCloud() async {
    setState(() => _isLoading = true);
    try {
      await CloudSyncService.uploadConfig();
      _showMessage('☁️ 已上传到云端');
    } catch (e) {
      _showMessage('❌ 上传失败: $e', bgColor: Colors.red);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _downloadFromCloud() async {
    setState(() => _isLoading = true);
    try {
      await CloudSyncService.downloadConfig();
      await _reloadNodes();
      _showMessage('✅ 已从云端同步');
    } catch (e) {
      _showMessage('❌ 下载失败: $e', bgColor: Colors.red);
    }
    setState(() => _isLoading = false);
  }

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
        return LayoutBuilder(
          builder: (context, constraints) {
            bool isLargeScreen = constraints.maxWidth > 600;
            bool isDesktop = Theme.of(context).platform == TargetPlatform.macOS ||
                Theme.of(context).platform == TargetPlatform.linux ||
                Theme.of(context).platform == TargetPlatform.windows;

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

            return isLargeScreen && isDesktop
                ? Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          color: Colors.grey[200],
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Service Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  const Text('Address: Socks5://127.0.0.1:1080'),
                                  const SizedBox(height: 8),
                                  const Text('Latency: N/A'),
                                  const SizedBox(height: 8),
                                  const Text('Loss: N/A'),
                                  const Divider(height: 32),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.sync),
                                    label: const Text('同步配置'),
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            try {
                                              await _reloadNodes();
                                              if (!mounted) return;
                                              final path = await VpnConfig.getConfigPath();
                                              if (!mounted) return;
                                              _showMessage('🔄 已同步配置文件：\n- $path');
                                            } catch (e) {
                                              if (!mounted) return;
                                              _showMessage('❌ 同步失败: $e', bgColor: Colors.red);
                                            }
                                          },
                                  ),
                                  const SizedBox(height: 4),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.delete_forever),
                                    label: const Text('删除配置'),
                                    onPressed: _isLoading || _selectedNodeNames.isEmpty
                                        ? null
                                        : _deleteSelectedNodes,
                                  ),
                                  const SizedBox(height: 4),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.save),
                                    label: const Text('保存配置'),
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            final path = await VpnConfig.getConfigPath();
                                            if (!mounted) return;
                                            await VpnConfig.saveToFile();
                                            if (!mounted) return;
                                            _showMessage('✅ 配置已保存到：\n$path');
                                          },
                                  ),
                                  const SizedBox(height: 4),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.cloud_upload),
                                    label: const Text('上传云端'),
                                    onPressed: _isLoading ? null : _uploadToCloud,
                                  ),
                                  const SizedBox(height: 4),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.cloud_download),
                                    label: const Text('下载云端'),
                                    onPressed: _isLoading ? null : _downloadFromCloud,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(flex: 2, child: content),
                    ],
                  )
                : content;
          },
        );
      },
    );
  }
}
