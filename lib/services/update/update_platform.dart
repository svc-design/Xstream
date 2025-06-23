// lib/services/update/update_platform.dart

import 'dart:io';

enum UpdateChannel { stable, latest }

class UpdatePlatform {
  static String getRepoName(UpdateChannel channel) {
    final base = switch (Platform.operatingSystem) {
      'macos' => 'xstream-macos',
      'windows' => 'xstream-windows',
      'android' => 'xstream-android',
      'linux' => 'xstream-linux',
      _ => throw UnsupportedError('Unsupported platform'),
    };
    return channel == UpdateChannel.latest ? '$base-latest' : '$base-stable';
  }
}
