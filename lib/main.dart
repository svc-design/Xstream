import 'dart:io';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/subscription_screen.dart';
import 'utils/app_theme.dart';
import 'utils/log_store.dart';
import 'utils/native_bridge.dart';
import 'utils/global_config.dart';
import 'services/telemetry/telemetry_service.dart';
import 'widgets/log_console.dart';
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
  TelemetryService.send(appVersion: _buildVersion());
}

String _buildVersion() {
  const branch = String.fromEnvironment('BRANCH_NAME', defaultValue: '');
  const buildId = String.fromEnvironment('BUILD_ID', defaultValue: 'local');
  const buildDate = String.fromEnvironment('BUILD_DATE', defaultValue: 'unknown');

  if (branch.startsWith('release/')) {
    final version = branch.replaceFirst('release/', '');
    return 'v$version-$buildDate-$buildId';
  }
  if (branch == 'main') {
    return 'latest-$buildDate-$buildId';
  }
  return 'dev-$buildDate-$buildId';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XStream'),
        actions: [
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
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          SubscriptionScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Subscriptions'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
