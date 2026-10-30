// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Front Porch AI is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Front Porch AI. If not, see <https://www.gnu.org/licenses/>.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'package:front_porch_ai/services/opencode/opencode_pin.dart';

/// Default download, unpack, port, remote-version, and health behaviours
/// for OpenCodeManager, extracted from opencode_manager.dart so that file
/// stays under the 500-line god-file bar. No behaviour change: these are
/// the same functions, used as the manager's defaults.

Future<List<int>> openCodeHttpDownload(
  Uri url, {
  void Function(int received, int? total)? onProgress,
}) async {
  final client = http.Client();
  try {
    final request = http.Request('GET', url);
    final response = await client.send(request);
    if (response.statusCode != 200) {
      throw Exception('OpenCode download failed: HTTP ${response.statusCode}');
    }
    final chunks = <int>[];
    var received = 0;
    await for (final chunk in response.stream) {
      chunks.addAll(chunk);
      received += chunk.length;
      onProgress?.call(received, response.contentLength);
    }
    return chunks;
  } finally {
    client.close();
  }
}

Future<File> openCodeUnpackZip(List<int> bytes, Directory dest) async {
  await dest.create(recursive: true);
  final linuxTar = bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
  final archive = File(linuxTar ? '${dest.path}.tar.gz' : '${dest.path}.zip');
  await archive.writeAsBytes(bytes, flush: true);
  try {
    if (linuxTar) {
      final r = await Process.run('tar', [
        '-xzf',
        archive.path,
        '-C',
        dest.path,
      ]).timeout(const Duration(minutes: 2));
      if (r.exitCode != 0) {
        throw Exception('Unpack failed: ${r.stderr}');
      }
      return openCodeFindUnpackedBinary(dest);
    }
    if (Platform.isWindows) {
      final r = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        'Expand-Archive -Force -Path "${archive.path}" '
            '-DestinationPath "${dest.path}"',
      ]).timeout(const Duration(minutes: 2));
      if (r.exitCode != 0) {
        throw Exception('Unpack failed: ${r.stderr}');
      }
    } else {
      final r = await Process.run('unzip', [
        '-o',
        archive.path,
        '-d',
        dest.path,
      ]).timeout(const Duration(minutes: 2));
      if (r.exitCode != 0) {
        throw Exception('Unpack failed: ${r.stderr}');
      }
    }
    return openCodeFindUnpackedBinary(dest);
  } finally {
    try {
      await archive.delete();
    } catch (_) {}
  }
}

File openCodeFindUnpackedBinary(Directory dest) {
  final want = Platform.isWindows ? 'opencode.exe' : 'opencode';
  final direct = File(p.join(dest.path, want));
  if (direct.existsSync()) return direct;
  for (final entity in dest.listSync(recursive: true, followLinks: false)) {
    if (entity is File && p.basename(entity.path) == want) {
      return entity;
    }
  }
  throw Exception('OpenCode zip did not contain $want');
}

Future<int> openCodePickFreePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<({String tag, int? assetBytes})?> openCodeFetchRemoteLatest() async {
  final client = http.Client();
  try {
    final resp = await client
        .get(
          Uri.parse(kOpenCodeGitHubLatestUrl),
          headers: {
            'Accept': 'application/vnd.github+json',
            'User-Agent': 'FrontPorchAI',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return null;
    final json = jsonDecode(resp.body);
    if (json is! Map) return null;
    final tag =
        (json['tag_name'] as String?)?.replaceFirst(RegExp(r'^[vV]'), '') ?? '';
    if (tag.isEmpty) return null;
    int? size;
    final want = openCodeReleaseAssetName(
      os: openCodeCurrentOs(),
      arch: openCodeCurrentArch(),
    );
    for (final a in json['assets'] as List? ?? []) {
      if (a is Map && a['name'] == want) {
        size = a['size'] as int?;
        break;
      }
    }
    return (tag: tag, assetBytes: size);
  } finally {
    client.close();
  }
}

Future<({bool healthy, String version})> openCodeGetHealth(Uri base) async {
  final uri = base.replace(path: '/global/health');
  final resp = await http.get(uri).timeout(const Duration(seconds: 2));
  if (resp.statusCode != 200) {
    return (healthy: false, version: '');
  }
  final json = jsonDecode(resp.body);
  if (json is! Map) return (healthy: false, version: '');
  return (
    healthy: json['healthy'] == true,
    version: (json['version'] as String?) ?? '',
  );
}
