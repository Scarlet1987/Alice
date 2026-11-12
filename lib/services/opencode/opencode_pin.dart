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
import 'dart:ffi';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:front_porch_ai/services/security/release_checksums.dart';

/// Honesty copy when GitHub has not told us the zip size yet.
const kOpenCodeDownloadMegabytes = 44;

const kOpenCodeGitHubOwner = 'anomalyco';
const kOpenCodeGitHubRepo = 'opencode';
const kOpenCodeVersionFileName = '.opencode_version';

const kOpenCodeGitHubLatestUrl =
    'https://api.github.com/repos/$kOpenCodeGitHubOwner/$kOpenCodeGitHubRepo/'
    'releases/latest';

const kOpenCodeGitHubLatestDownloadBase =
    'https://github.com/$kOpenCodeGitHubOwner/$kOpenCodeGitHubRepo/'
    'releases/latest/download';

String openCodeCurrentOs() {
  if (Platform.isMacOS) return 'darwin';
  if (Platform.isWindows) return 'windows';
  return 'linux';
}

String openCodeCurrentArch() {
  switch (Abi.current()) {
    case Abi.macosArm64:
    case Abi.linuxArm64:
    case Abi.windowsArm64:
      return 'arm64';
    default:
      return 'x64';
  }
}

/// GitHub layout: Mac/Windows zip, Linux tar.gz. Not musl/baseline.
String openCodeReleaseAssetName({required String os, required String arch}) {
  if (os == 'linux') return 'opencode-linux-$arch.tar.gz';
  return 'opencode-$os-$arch.zip';
}

String openCodeDownloadUrl({
  required String version,
  required String os,
  required String arch,
}) {
  final asset = openCodeReleaseAssetName(os: os, arch: arch);
  return 'https://github.com/$kOpenCodeGitHubOwner/$kOpenCodeGitHubRepo/'
      'releases/download/v$version/$asset';
}

/// Same shape as Kobold: `releases/latest/download/<asset>`.
Uri openCodeLatestDownloadUri({String? os, String? arch}) {
  final asset = openCodeReleaseAssetName(
    os: os ?? openCodeCurrentOs(),
    arch: arch ?? openCodeCurrentArch(),
  );
  return Uri.parse('$kOpenCodeGitHubLatestDownloadBase/$asset');
}

/// Fetches the published SHA-256 for this platform's OpenCode asset in
/// release [tag] (without the leading `v`), or null when the release
/// publishes no hash for it. The only trusted source is a per-asset
/// `<asset>.sha256` or a `SHA256SUMS` manifest published with the
/// anomalyco/opencode release; v1.19.5 publishes neither, so installs fail
/// closed until upstream publishes one. Never invent a hash value.
/// [apiBase] is a test seam for the GitHub API base URL.
Future<String?> openCodeFetchReleaseChecksum(String tag, {Uri? apiBase}) async {
  final asset = openCodeReleaseAssetName(
    os: openCodeCurrentOs(),
    arch: openCodeCurrentArch(),
  );
  final base =
      apiBase ??
      Uri.parse(
        'https://api.github.com/repos/$kOpenCodeGitHubOwner/$kOpenCodeGitHubRepo/',
      );
  final client = http.Client();
  try {
    final resp = await client
        .get(
          base.resolve('releases/tags/v$tag'),
          headers: {
            'Accept': 'application/vnd.github+json',
            'User-Agent': 'FrontPorchAI',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return null;
    final json = jsonDecode(resp.body);
    if (json is! Map) return null;
    final sumsUrl = findChecksumAssetUrl(json['assets'] as List? ?? [], asset);
    if (sumsUrl == null) return null;
    if (sumsUrl.toLowerCase().endsWith('.sha256')) {
      return await fetchSha256FromUrl(client: client, url: Uri.parse(sumsUrl));
    }
    return await fetchSha256ForAsset(
      client: client,
      sumsUrl: sumsUrl,
      assetName: asset,
    );
  } catch (_) {
    return null;
  } finally {
    client.close();
  }
}

bool openCodeLooksLikeBrewPath(String path) {
  final n = path.replaceAll('\\', '/').toLowerCase();
  if (n.contains('/opt/homebrew/')) return true;
  if (n.contains('/home/linuxbrew/')) return true;
  if (n.contains('/.linuxbrew/')) return true;
  if (n.endsWith('/usr/local/bin/opencode')) return true;
  if (n.endsWith('/usr/local/bin/opencode.exe')) return true;
  return false;
}

bool openCodeLooksLikeUserConfigPath(String path) {
  final n = path.replaceAll('\\', '/');
  if (n.contains('/.config/opencode')) return true;
  if (n.toLowerCase().contains('/appdata/roaming/opencode')) return true;
  return false;
}

/// Settings / Waifu honesty: on-disk vs GitHub latest. Tap installs latest.
String openCodeUpgradeHonesty({
  required String? installed,
  String? remote,
  int megabytes = kOpenCodeDownloadMegabytes,
}) {
  final remoteBit = (remote == null || remote.isEmpty)
      ? ''
      : ' GitHub latest is $remote.';
  if (installed == null || installed.isEmpty) {
    return 'OpenCode is not in the closet yet (~${megabytes}MB).'
        '$remoteBit Homebrew is not used.';
  }
  if (remote != null && remote.isNotEmpty && installed != remote) {
    return 'OpenCode $installed → $remote, ~${megabytes}MB.';
  }
  if (remote != null && remote.isNotEmpty && installed == remote) {
    return 'OpenCode $remote is current.$remoteBit '
        'Homebrew and ~/.config/opencode are not the product copy.';
  }
  return 'OpenCode $installed is installed.$remoteBit Homebrew is not used.';
}

/// Same button words as the managed Kobold row.
String openCodeUpgradeButtonLabel({
  required String? installed,
  String? remote,
  String? versionError,
}) {
  if (installed == null || installed.isEmpty) {
    return 'Download';
  }
  if (versionError != null && versionError.isNotEmpty) {
    return 'Check (failed)';
  }
  if (remote == null || remote.isEmpty) {
    return 'Check for Updates';
  }
  if (installed != remote) {
    return 'Update to v$remote';
  }
  return 'Up to date';
}
