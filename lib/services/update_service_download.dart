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

part of 'update_service.dart';

/// Verifies a staged installer against the release's published checksum
/// source. Fail-closed: throws and deletes [file] when the release publishes
/// no hash for [assetName] or the bytes do not match. The download entry
/// point ([UpdateServiceDownload._downloadUpdateImpl]) calls this before
/// staging; tests drive it directly against a local checksum server.
@visibleForTesting
Future<void> verifyStagedUpdateInstaller({
  required File file,
  required String assetName,
  required String? sha256SumsUrl,
  http.Client? client,
}) => verifyFileAgainstChecksumSource(
  file: file,
  assetName: assetName,
  sumsUrl: sha256SumsUrl,
  assetLabel: 'self-update $assetName',
  client: client,
);

/// Download the chosen GitHub asset to a temp file.
extension UpdateServiceDownload on UpdateService {
  /// Download the installer to a temp directory.
  /// Does NOT run it — call installNow() or let installOnClose() handle it.
  Future<void> _downloadUpdateImpl() async {
    if (!UpdateService.isSupported || _downloadUrl.isEmpty || _downloading) {
      return;
    }

    _downloading = true;
    _downloadComplete = false;
    _downloadProgress = 0.0;
    notify();

    try {
      // Unique temp dir per download — a predictable path in the shared temp
      // dir allows symlink planting between validation and install (§3g).
      final tempDir = await Directory.systemTemp.createTemp('fpai_update_');
      // Use the resolved asset name so the temp file has the correct
      // extension for the later install dispatch.
      final assetName = _selectedAssetName.isNotEmpty
          ? _selectedAssetName
          : UpdateService._platformAsset;
      final sep = Platform.isWindows ? '\\' : '/';
      final installerPath = '${tempDir.path}$sep$assetName';
      final file = File(installerPath);

      final request = http.Request('GET', Uri.parse(_downloadUrl));
      final client = http.Client();
      try {
        final response = await client.send(request);
        // A 404/500 HTML error page must never become "the installer":
        // the Linux path deletes the RUNNING AppImage before copying, so a
        // garbage file that passed this point destroyed the install.
        if (response.statusCode != 200) {
          throw Exception('installer download HTTP ${response.statusCode}');
        }

        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;
        final sink = file.openWrite();
        try {
          await for (final chunk in response.stream) {
            sink.add(chunk);
            receivedBytes += chunk.length;
            if (totalBytes > 0) {
              _downloadProgress = receivedBytes / totalBytes;
              notify();
            }
          }
        } finally {
          await sink.close();
        }

        final invalid = UpdateService.validateInstallerDownload(
          receivedBytes: receivedBytes,
          expectedBytes: totalBytes,
        );
        if (invalid != null) throw Exception(invalid);
        // A complete fake 200 (a captive portal / CDN error page big enough
        // to pass the size floor) must still not become the installer: an
        // HTML body is text, real installers are binary. First byte '<' (or
        // a leading doctype after whitespace) = not an installer.
        final head = await file
            .openRead(0, 64)
            .fold<List<int>>(<int>[], (a, b) => a..addAll(b));
        final headText = String.fromCharCodes(head).trimLeft().toLowerCase();
        if (headText.startsWith('<')) {
          throw Exception('installer download is an HTML page, not a binary');
        }

        // Integrity: refuse to stage an installer whose bytes don't match
        // the hash published with the release (SHA256SUMS manifest or a
        // per-asset .sha256). A release with no published hash for this
        // asset fails closed: the download is deleted and nothing stages.
        await verifyStagedUpdateInstaller(
          file: file,
          assetName: assetName,
          sha256SumsUrl: _sha256SumsUrl.isEmpty ? null : _sha256SumsUrl,
          client: client,
        );

        _pendingInstallerPath = installerPath;
        _downloadComplete = true;
        _downloading = false;
        notify();
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Download error: $e');
      _downloading = false;
      _downloadProgress = 0.0;
      notify();
    }
  }
}
