import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/global_config.dart';

class TelemetryService {
  static const _prefsKey = 'telemetryEnabled';
  static final DateTime _startTime = DateTime.now();

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefsKey) ?? false;
    GlobalState.telemetryEnabled.value = enabled;
    GlobalState.telemetryEnabled.addListener(() {
      prefs.setBool(_prefsKey, GlobalState.telemetryEnabled.value);
    });
  }

  static Future<void> send({required String appVersion}) async {
    if (!GlobalState.telemetryEnabled.value) return;

    final payload = {
      'appVersion': appVersion,
      'os': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
      'dartVersion': Platform.version,
      'uptime': DateTime.now().difference(_startTime).inSeconds,
    };

    try {
      await http.post(
        Uri.parse(kTelemetryEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (_) {
      // ignore errors silently
    }
  }
}
