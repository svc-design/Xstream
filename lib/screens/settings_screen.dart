import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/global_config.dart' show GlobalState, buildVersion, logConsoleKey;
import '../../utils/native_bridge.dart';
import '../../services/vpn_config_service.dart';
import '../../services/update/update_checker.dart';
import '../../services/update/update_platform.dart';
import '../../services/telemetry/telemetry_service.dart';
import '../widgets/log_console.dart' show LogLevel;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Timer? _xrayMonitorTimer;

  static const TextStyle _menuTextStyle = TextStyle(fontSize: 14);
  static final ButtonStyle _menuButtonStyle = ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(36),
    textStyle: _menuTextStyle,
  );

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    ButtonStyle? style,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: style ?? _menuButtonStyle,
        icon: Icon(icon),
        label: Text(label, style: _menuTextStyle),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }

  String _currentVersion() {
    final match = RegExp(r'v(\d+\.\d+\.\d+)').firstMatch(buildVersion);
    return match?.group(1) ?? '0.0.0';
  }

  void _onGenerateDefaultNodes() async {
    final isUnlocked = GlobalState.isUnlocked.value;
    final password = GlobalState.sudoPassword.value;

    if (!isUnlocked) {
      logConsoleKey.currentState?.addLog('请先解锁以执行生成操作', level: LogLevel.warning);
      return;
    }

    logConsoleKey.currentState?.addLog('开始生成默认节点...');
    await VpnConfig.generateDefaultNodes(
      password: password,
      setMessage: (msg) => logConsoleKey.currentState?.addLog(msg),
      logMessage: (msg) => logConsoleKey.currentState?.addLog(msg),
    );
  }

  void _onInitXray() async {
    final isUnlocked = GlobalState.isUnlocked.value;

    if (!isUnlocked) {
      logConsoleKey.currentState?.addLog('请先解锁以初始化 Xray', level: LogLevel.warning);
      return;
    }

    logConsoleKey.currentState?.addLog('开始初始化 Xray...');
    try {
      final output = await NativeBridge.initXray();
      logConsoleKey.currentState?.addLog(output);
    } catch (e) {
      logConsoleKey.currentState?.addLog('[错误] $e', level: LogLevel.error);
    }
  }

  void _onUpdateXray() async {
    final isUnlocked = GlobalState.isUnlocked.value;

    if (!isUnlocked) {
      logConsoleKey.currentState?.addLog('请先解锁以更新 Xray', level: LogLevel.warning);
      return;
    }

    logConsoleKey.currentState?.addLog('开始更新 Xray Core...');
    try {
      final output = await NativeBridge.updateXrayCore();
      logConsoleKey.currentState?.addLog(output);
      if (output.startsWith('info:')) {
        GlobalState.xrayUpdating.value = true;
        _startMonitorXrayProgress();
      }
    } catch (e) {
      logConsoleKey.currentState?.addLog('[错误] $e', level: LogLevel.error);
    }
  }

  void _startMonitorXrayProgress() {
    _xrayMonitorTimer?.cancel();
    _xrayMonitorTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final running = await NativeBridge.isXrayDownloading();
      GlobalState.xrayUpdating.value = running;
      if (!running) {
        _xrayMonitorTimer?.cancel();
      }
    });
  }

  void _onResetAll() async {
    final isUnlocked = GlobalState.isUnlocked.value;
    final password = GlobalState.sudoPassword.value;

    if (!isUnlocked) {
      logConsoleKey.currentState?.addLog('请先解锁以执行重置操作', level: LogLevel.warning);
      return;
    }

    logConsoleKey.currentState?.addLog('开始重置配置与文件...');
    try {
      final result = await NativeBridge.resetXrayAndConfig(password);
      logConsoleKey.currentState?.addLog(result);
    } catch (e) {
      logConsoleKey.currentState?.addLog('[错误] 重置失败: $e', level: LogLevel.error);
    }
  }

  void _onSyncConfig() async {
    logConsoleKey.currentState?.addLog('开始同步配置...');
    try {
      await VpnConfig.load();
      logConsoleKey.currentState?.addLog('✅ 已同步配置文件');
    } catch (e) {
      logConsoleKey.currentState?.addLog('[错误] 同步失败: $e', level: LogLevel.error);
    }
  }

  void _onDeleteConfig() async {
    final isUnlocked = GlobalState.isUnlocked.value;
    if (!isUnlocked) {
      logConsoleKey.currentState?.addLog('请先解锁以删除配置', level: LogLevel.warning);
      return;
    }

    logConsoleKey.currentState?.addLog('开始删除配置...');
    try {
      final nodes = List<VpnNode>.from(VpnConfig.nodes);
      for (final node in nodes) {
        await VpnConfig.deleteNodeFiles(node);
      }
      await VpnConfig.load();
      logConsoleKey.currentState?.addLog('✅ 已删除 ${nodes.length} 个节点并更新配置');
    } catch (e) {
      logConsoleKey.currentState?.addLog('[错误] 删除失败: $e', level: LogLevel.error);
    }
  }

  void _onSaveConfig() async {
    logConsoleKey.currentState?.addLog('开始保存配置...');
    try {
      final path = await VpnConfig.getConfigPath();
      await VpnConfig.saveToFile();
      logConsoleKey.currentState?.addLog('✅ 配置已保存到: $path');
    } catch (e) {
      logConsoleKey.currentState?.addLog('[错误] 保存失败: $e', level: LogLevel.error);
    }
  }

  void _onCheckUpdate() {
    logConsoleKey.currentState?.addLog('开始检查更新...');
    UpdateChecker.manualCheck(
      context,
      currentVersion: _currentVersion(),
      channel: GlobalState.useDailyBuild.value ? UpdateChannel.latest : UpdateChannel.stable,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ 设置中心',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: GlobalState.isUnlocked,
              builder: (context, isUnlocked, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('Xray 管理', [
                          _buildButton(
                              icon: Icons.build,
                              label: '初始化 Xray',
                              onPressed: isUnlocked ? _onInitXray : null),
                          _buildButton(
                              icon: Icons.update,
                              label: '更新 Xray Core',
                              onPressed: isUnlocked ? _onUpdateXray : null),
                          ValueListenableBuilder<bool>(
                            valueListenable: GlobalState.xrayUpdating,
                            builder: (context, downloading, _) {
                              return downloading
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 4),
                                      child: LinearProgressIndicator(),
                                    )
                                  : const SizedBox.shrink();
                            },
                          ),
                        ]),
                        _buildSection('配置管理', [
                          _buildButton(
                              icon: Icons.settings,
                              label: '生成默认节点',
                              onPressed:
                                  isUnlocked ? _onGenerateDefaultNodes : null),
                          _buildButton(
                              icon: Icons.restore,
                              label: '重置所有配置',
                              style: _menuButtonStyle.copyWith(
                                  backgroundColor:
                                      WidgetStateProperty.all(Colors.red[400])),
                              onPressed: isUnlocked ? _onResetAll : null),
                          _buildButton(
                              icon: Icons.sync,
                              label: '同步配置',
                              onPressed: isUnlocked ? _onSyncConfig : null),
                          _buildButton(
                              icon: Icons.delete_forever,
                              label: '删除配置',
                              onPressed: isUnlocked ? _onDeleteConfig : null),
                          _buildButton(
                              icon: Icons.save,
                              label: '保存配置',
                              onPressed: isUnlocked ? _onSaveConfig : null),
                        ]),
                        if (!isUnlocked)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              '请先解锁以执行初始化操作',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 32),
              SwitchListTile(
                secondary: const Icon(Icons.bolt),
                title: const Text('升级 DailyBuild', style: _menuTextStyle),
                value: GlobalState.useDailyBuild.value,
                onChanged: (v) {
                  setState(() => GlobalState.useDailyBuild.value = v);
                  logConsoleKey.currentState?.addLog('升级 DailyBuild: ${v ? "开启" : "关闭"}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.stacked_line_chart),
                title: const Text('查看收集内容', style: _menuTextStyle),
                trailing: Switch(
                  value: GlobalState.telemetryEnabled.value,
                  onChanged: (v) {
                    setState(() => GlobalState.telemetryEnabled.value = v);
                    logConsoleKey.currentState?.addLog('Telemetry: ${v ? "开启" : "关闭"}');
                  },
                ),
                onTap: _showTelemetryData,
              ),
              ListTile(
                leading: const Icon(Icons.system_update),
                title: const Text('检查更新', style: _menuTextStyle),
                onTap: _onCheckUpdate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _xrayMonitorTimer?.cancel();
    super.dispose();
  }

  void _showTelemetryData() {
    final data = TelemetryService.collectData(appVersion: buildVersion);
    final json = const JsonEncoder.withIndent('  ').convert(data);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('收集内容'),
        content: SingleChildScrollView(
          child: SelectableText(json),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
