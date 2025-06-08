// lib/services/update/update_platform.dart

import 'dart:io';

enum UpdateChannel { stable, beta }

class UpdatePlatform {
  static String getRepoName(UpdateChannel channel) {
    final base = switch (Platform.operatingSystem) {
      'macos' => 'xstream-macos',
      'windows' => 'xstream-win',
      'android' => 'xstream-android',
      'linux' => 'xstream-deb',
      _ => throw UnsupportedError('Unsupported platform'),
    };
    return channel == UpdateChannel.beta ? '$base-beta' : '$base-stable';
  }
}
