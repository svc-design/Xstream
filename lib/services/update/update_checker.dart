// lib/services/update/update_checker.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'update_service.dart';
import 'update_platform.dart';
import '../../utils/global_config.dart';

class UpdateChecker {
  static const _lastVersionKey = 'lastCheckedVersion';

  static void schedulePeriodicCheck({
    required BuildContext context,
    required String currentVersion,
    required UpdateChannel channel,
  }) {
    Timer.periodic(const Duration(hours: 6), (_) {
      _check(context, currentVersion: currentVersion, channel: channel);
    });
  }

  static Future<void> manualCheck(
    BuildContext context, {
    required String currentVersion,
    required UpdateChannel channel,
  }) async {
    await _check(context, currentVersion: currentVersion, channel: channel, manual: true);
  }

  static Future<void> _check(
    BuildContext context, {
    required String currentVersion,
    required UpdateChannel channel,
    bool manual = false,
  }) async {
    if (!context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final lastVersion = prefs.getString(_lastVersionKey) ?? '0.0.0';

    final repoName = UpdatePlatform.getRepoName(channel);
    const baseUrl = UpdateService.baseUrl; // ✅ 不再是 pulpBaseUrl
    final repoUrl = '$baseUrl/$repoName/';

    logConsoleKey.currentState?.addLog('[INFO] 开始检查更新...');
    logConsoleKey.currentState?.addLog('[DEBUG] 当前版本: $currentVersion');
    logConsoleKey.currentState?.addLog('[DEBUG] 检查地址: $repoUrl');

    final info = await UpdateService.checkUpdate(
      repoUrl: repoUrl,
      currentVersion: currentVersion,
    );

    if (!context.mounted) return;

    if (info != null && info.version != lastVersion) {
      logConsoleKey.currentState?.addLog('[INFO] 发现新版本: ${info.version}');
      logConsoleKey.currentState?.addLog('[INFO] 下载地址: ${info.url}');
      prefs.setString(_lastVersionKey, info.version);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('发现新版本 ${info.version}'),
          content: Text(info.notes),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse(info.url));
              },
              child: const Text('下载'),
            ),
          ],
        ),
      );
    } else {
      logConsoleKey.currentState?.addLog('[INFO] 没有检测到新版本');
      if (manual) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已是最新版本')),
        );
      }
    }
  }
}
