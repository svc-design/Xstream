import 'dart:io';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/help_screen.dart';
import 'screens/about_screen.dart';
import 'utils/app_theme.dart';
import 'utils/log_store.dart';
import 'utils/native_bridge.dart';
import 'widgets/log_console.dart';
import 'utils/global_config.dart' show GlobalState, logConsoleKey;
import 'services/telemetry/telemetry_service.dart';
import 'services/vpn_config_service.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await TelemetryService.init();
  final debug = args.contains('--debug') ||
      Platform.executableArguments.contains('--debug');
  GlobalState.debugMode.value = debug;
  if (debug) {
    debugPrint('🚀 Flutter main() started in debug mode');
  }
  await VpnConfig.load(); // ✅ 启动时加载 assets + 本地配置
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XStream',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ✅ 注册生命周期观察器

    NativeBridge.initializeLogger((log) {
      logConsoleKey.currentState?.addLog("[macOS] $log");
      LogStore.addLog(LogLevel.info, "[macOS] $log");
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ✅ 注销生命周期观察器
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      // ✅ 退出前自动保存配置
      VpnConfig.saveToFile();
    }
  }

  Future<void> _promptUnlockDialog() async {
    String? password = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('输入密码解锁'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: '密码'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('确认')),
          ],
        );
      },
    );

    if (password != null && password.isNotEmpty) {
      GlobalState.isUnlocked.value = true;
      GlobalState.sudoPassword.value = password;
    }
  }

  void _lock() {
    GlobalState.isUnlocked.value = false;
    GlobalState.sudoPassword.value = '';
  }

  void _openAddConfig() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  void _showModeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<String>(
          valueListenable: GlobalState.connectionMode,
          builder: (context, mode, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Radio<String>(
                    value: 'VPN',
                    groupValue: mode,
                    onChanged: (v) {
                      if (v != null) GlobalState.connectionMode.value = v;
                      Navigator.pop(context);
                    },
                  ),
                  title: const Text('VPN'),
                ),
                ListTile(
                  leading: Radio<String>(
                    value: '仅代理',
                    groupValue: mode,
                    onChanged: (v) {
                      if (v != null) GlobalState.connectionMode.value = v;
                      Navigator.pop(context);
                    },
                  ),
                  title: const Text('仅代理'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeScreen(),
      const SubscriptionScreen(),
      const SettingsScreen(),
      const LogsScreen(),
      const HelpScreen(),
      const AboutScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [
          IconButton(
            tooltip: '添加配置文件',
            icon: const Icon(Icons.add),
            onPressed: _openAddConfig,
          ),
          ValueListenableBuilder<bool>(
            valueListenable: GlobalState.isUnlocked,
            builder: (context, unlocked, _) {
              return IconButton(
                icon: Icon(unlocked ? Icons.lock_open : Icons.lock),
                onPressed: unlocked ? _lock : _promptUnlockDialog,
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.home), label: Text('首页')),
              NavigationRailDestination(icon: Icon(Icons.link), label: Text('代理')),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text('设置')),
              NavigationRailDestination(icon: Icon(Icons.article), label: Text('日志')),
              NavigationRailDestination(icon: Icon(Icons.help), label: Text('帮助')),
              NavigationRailDestination(icon: Icon(Icons.info), label: Text('关于')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: IndexedStack(index: _currentIndex, children: pages)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showModeSelector,
        child: const Icon(Icons.tune),
      ),
    );
  }
}
