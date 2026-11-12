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

// Finding 3 (OpenCode): the managed binary is downloaded from a pinned
// release tag and unpacked only when the bytes match the SHA-256 published
// with that release. A tampered download or a release with no published
// hash must throw before any unpack or execute.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:front_porch_ai/services/opencode/opencode.dart';

String _sha(List<int> bytes) => sha256.convert(bytes).toString();

Future<HttpServer> _startServer(
  FutureOr<void> Function(HttpRequest req) handler,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    try {
      await handler(req);
    } catch (_) {
      try {
        req.response.statusCode = 500;
        await req.response.close();
      } catch (_) {}
    }
  });
  return server;
}

void _respond(HttpRequest req, int status, List<int> body) {
  req.response.statusCode = status;
  req.response.contentLength = body.length;
  req.response.add(body);
  req.response.close();
}

void main() {
  // flutter_test mocks HttpClient by default (every request returns 400);
  // these tests talk real HTTP to a local server they control.
  setUpAll(() => HttpOverrides.global = null);

  group('OpenCodeManager checksum gate', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('fpai_oc_sum_');
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    OpenCodeManager manager({
      required Future<List<int>> Function(
        Uri url, {
        void Function(int received, int? total)? onProgress,
      })
      downloader,
      required Future<String?> Function(String tag) checksumLookup,
      String? tag,
      required List<Uri> capturedUrls,
      required List<List<int>> unpacked,
    }) {
      return OpenCodeManager(
        rootPath: root.path,
        remoteLookup: () async =>
            tag == null ? null : (tag: tag, assetBytes: 1024),
        downloader: (url, {onProgress}) async {
          capturedUrls.add(url);
          return downloader(url, onProgress: onProgress);
        },
        checksumLookup: checksumLookup,
        unpack: (bytes, dest) async {
          unpacked.add(bytes);
          final bin = File(
            p.join(dest.path, OpenCodeCloset(root.path).binaryName),
          );
          await bin.writeAsString('BIN');
          return bin;
        },
      );
    }

    test(
      'installs from the pinned versioned URL when the hash matches',
      () async {
        final bytes = utf8.encode('opencode-archive-bytes');
        final capturedUrls = <Uri>[];
        final unpacked = <List<int>>[];
        final mgr = manager(
          tag: '1.19.5',
          capturedUrls: capturedUrls,
          unpacked: unpacked,
          downloader: (url, {onProgress}) async => bytes,
          checksumLookup: (tag) async => _sha(bytes),
        );

        await mgr.ensureInstalled();

        expect(capturedUrls, hasLength(1));
        expect(
          capturedUrls.single.toString(),
          'https://github.com/anomalyco/opencode/releases/download/v1.19.5/'
          '${openCodeReleaseAssetName(os: openCodeCurrentOs(), arch: openCodeCurrentArch())}',
        );
        expect(unpacked, hasLength(1));
        expect(unpacked.single, bytes);
        expect(await File(mgr.closet.binaryPath).readAsString(), 'BIN');
        expect(mgr.installedVersion, '1.19.5');
      },
    );

    test('tampered bytes are blocked before unpack', () async {
      final realBytes = utf8.encode('opencode-archive-bytes');
      final unpacked = <List<int>>[];
      final mgr = manager(
        tag: '1.19.5',
        capturedUrls: <Uri>[],
        unpacked: unpacked,
        downloader: (url, {onProgress}) async =>
            utf8.encode('tampered archive'),
        checksumLookup: (tag) async => _sha(realBytes),
      );

      await expectLater(mgr.ensureInstalled(), throwsA(isA<StateError>()));
      expect(unpacked, isEmpty);
      expect(await mgr.isInstalled, isFalse);
      expect(mgr.error, contains('SHA-256 mismatch'));
    });

    test('a release with no published hash is blocked before unpack', () async {
      // Live upstream state for v1.19.5: no .sha256 / SHA256SUMS asset.
      final unpacked = <List<int>>[];
      final mgr = manager(
        tag: '1.19.5',
        capturedUrls: <Uri>[],
        unpacked: unpacked,
        downloader: (url, {onProgress}) async =>
            utf8.encode('opencode-archive-bytes'),
        checksumLookup: (tag) async => null,
      );

      await expectLater(mgr.ensureInstalled(), throwsA(isA<StateError>()));
      expect(unpacked, isEmpty);
      expect(await mgr.isInstalled, isFalse);
      expect(mgr.error, contains('No published SHA-256'));
    });

    test('an unknown release tag is blocked before downloading', () async {
      var downloads = 0;
      final mgr = manager(
        tag: null,
        capturedUrls: <Uri>[],
        unpacked: <List<int>>[],
        downloader: (url, {onProgress}) async {
          downloads++;
          return utf8.encode('x');
        },
        checksumLookup: (tag) async => _sha(utf8.encode('x')),
      );

      await expectLater(mgr.ensureInstalled(), throwsA(isA<StateError>()));
      expect(downloads, 0);
    });
  });

  group('openCodeFetchReleaseChecksum', () {
    late HttpServer server;

    tearDown(() async {
      await server.close(force: true);
    });

    Uri apiBase() =>
        Uri.parse('http://127.0.0.1:${server.port}/repos/anomalyco/opencode/');

    test('returns the hash from a published per-asset .sha256', () async {
      final hex = _sha(utf8.encode('archive'));
      final asset = openCodeReleaseAssetName(
        os: openCodeCurrentOs(),
        arch: openCodeCurrentArch(),
      );
      server = await _startServer((req) async {
        if (req.uri.path.endsWith('/releases/tags/v1.19.5')) {
          final body = jsonEncode({
            'tag_name': 'v1.19.5',
            'assets': [
              {
                'name': '$asset.sha256',
                'browser_download_url':
                    'http://127.0.0.1:${server.port}/$asset.sha256',
              },
            ],
          });
          _respond(req, 200, utf8.encode(body));
        } else if (req.uri.path.endsWith('/$asset.sha256')) {
          _respond(req, 200, utf8.encode('$hex  $asset\n'));
        } else {
          _respond(req, 404, utf8.encode('nope'));
        }
      });

      expect(
        await openCodeFetchReleaseChecksum('1.19.5', apiBase: apiBase()),
        hex,
      );
    });

    test('returns null when the release publishes no hash asset', () async {
      final asset = openCodeReleaseAssetName(
        os: openCodeCurrentOs(),
        arch: openCodeCurrentArch(),
      );
      server = await _startServer((req) async {
        if (req.uri.path.endsWith('/releases/tags/v1.19.5')) {
          final body = jsonEncode({
            'tag_name': 'v1.19.5',
            'assets': [
              {'name': asset, 'browser_download_url': 'http://x/y'},
            ],
          });
          _respond(req, 200, utf8.encode(body));
        } else {
          _respond(req, 404, utf8.encode('nope'));
        }
      });

      expect(
        await openCodeFetchReleaseChecksum('1.19.5', apiBase: apiBase()),
        isNull,
      );
    });

    test('returns null when the release lookup fails', () async {
      server = await _startServer((req) async {
        _respond(req, 404, utf8.encode('nope'));
      });

      expect(
        await openCodeFetchReleaseChecksum('9.9.9', apiBase: apiBase()),
        isNull,
      );
    });
  });
}
