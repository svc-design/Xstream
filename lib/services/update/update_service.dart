// lib/services/update/update_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/update_info.dart';

class UpdateService {
  static const String pulpBaseUrl = 'https://artifact.svc.plus';

  static Future<UpdateInfo?> checkUpdate({
    required String repoName,
    required String currentVersion,
  }) async {
    try {
      final versionResp = await http.get(Uri.parse(
          '$pulpBaseUrl/pulp/api/v3/repositories/file/file/$repoName/versions/latest/'));
      if (versionResp.statusCode != 200) return null;

      final versionHref = jsonDecode(versionResp.body)['pulp_href'];

      final contentResp = await http.get(Uri.parse(
          '$pulpBaseUrl/pulp/api/v3/content/file/files/?repository_version=$versionHref&ordering=-pulp_created'));
      if (contentResp.statusCode != 200) return null;

      final results = jsonDecode(contentResp.body)['results'] as List;
      final file = results.firstWhere(
        (e) => e['relative_path'].toString().contains(RegExp(r'\.dmg|\.exe|\.apk')),
        orElse: () => null,
      );
      if (file == null) return null;

      final fileName = file['relative_path'];
      final match = RegExp(r'(\d+\.\d+\.\d+)').firstMatch(fileName);
      if (match == null) return null;

      final remoteVersion = match.group(1)!;
      if (!_isNewerVersion(currentVersion, remoteVersion)) return null;

      return UpdateInfo(
        version: remoteVersion,
        url: '$pulpBaseUrl/pulp/content/$repoName/$fileName',
        notes: 'Version $remoteVersion available.',
      );
    } catch (_) {
      return null;
    }
  }

  static bool _isNewerVersion(String local, String remote) {
    final l = local.split('.').map(int.parse).toList();
    final r = remote.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false;
  }
}
