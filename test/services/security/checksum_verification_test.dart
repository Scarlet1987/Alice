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

// Finding 3: every download→execute pipeline must fail closed on a missing
// or mismatched checksum. These tests drive each pipeline's verification
// entry point against a real local HTTP server serving real fixture files —
// the verification itself is never stubbed.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:front_porch_ai/models/download_task.dart';
import 'package:front_porch_ai/services/backend_manager.dart';
import 'package:front_porch_ai/services/download_manager.dart';
import 'package:front_porch_ai/services/security/release_checksums.dart';
import 'package:front_porch_ai/services/security/verify_sha256.dart';
import 'package:front_porch_ai/services/update_service.dart';

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

Uri _url(HttpServer server, String path) =>
    Uri.parse('http://127.0.0.1:${server.port}$path');

void _respond(HttpRequest req, int status, List<int> body) {
  req.response.statusCode = status;
  req.response.contentLength = body.length;
  req.response.add(body);
  req.response.close();
}

Future<void> _waitForTask(
  DownloadTask task,
  bool Function() done, {
  String what = 'task to settle',
}) async {
  for (var i = 0; i < 200; i++) {
    if (done()) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  fail(
    'timed out waiting for $what '
    '(state=${task.state}, error=${task.errorMessage})',
  );
}

void main() {
  // flutter_test mocks HttpClient by default (every request returns 400);
  // these tests talk real HTTP to a local server they control.
  setUpAll(() => HttpOverrides.global = null);

  group('parseSha256Sums', () {
    test('matches two-space and binary-marker entries', () {
      const text =
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
          '  app_1.0_amd64.deb\n'
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
          ' *other.bin\n';
      expect(parseSha256Sums(text, 'app_1.0_amd64.deb'), 'a' * 64);
      expect(parseSha256Sums(text, 'other.bin'), 'b' * 64);
    });

    test('tolerates CRLF and case differences in the name', () {
      final text = '${'c' * 64}  Front-Porch-AI_1.5.0_amd64.deb\r\n';
      expect(parseSha256Sums(text, 'front-porch-ai_1.5.0_amd64.deb'), 'c' * 64);
    });

    test('returns null for a missing entry or a malformed line', () {
      const text =
          'not-a-hash  app.deb\n'
          'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd'
          '  other.deb\n';
      expect(parseSha256Sums(text, 'app.deb'), isNull);
      expect(parseSha256Sums(text, 'missing.deb'), isNull);
    });
  });

  group('parseSha256File', () {
    test('accepts a bare hex digest and the hex-plus-name form', () {
      expect(parseSha256File('${'e' * 64}\n'), 'e' * 64);
      expect(
        parseSha256File("${'f' * 64}  Tailscale-1.0-macos.pkg\n"),
        'f' * 64,
      );
    });

    test('returns null when no 64-hex token is present', () {
      expect(parseSha256File('not a checksum\n'), isNull);
      expect(parseSha256File(''), isNull);
    });
  });

  group('findChecksumAssetUrl', () {
    test('prefers a per-asset .sha256 over SHA256SUMS', () {
      final assets = [
        {
          'name': 'SHA256SUMS',
          'browser_download_url': 'https://example.invalid/SHA256SUMS',
        },
        {
          'name': 'koboldcpp.exe.sha256',
          'browser_download_url': 'https://example.invalid/k.exe.sha256',
        },
      ];
      expect(
        findChecksumAssetUrl(assets, 'koboldcpp.exe'),
        'https://example.invalid/k.exe.sha256',
      );
      expect(
        findChecksumAssetUrl(assets, 'other.bin'),
        'https://example.invalid/SHA256SUMS',
      );
    });

    test('returns null when the release publishes no hash asset', () {
      expect(
        findChecksumAssetUrl([
          {'name': 'koboldcpp.exe', 'browser_download_url': 'https://x/y'},
        ], 'koboldcpp.exe'),
        isNull,
      );
    });
  });

  group('fetch + resolve over a real local server', () {
    late HttpServer server;
    late http.Client client;

    setUp(() async {
      client = http.Client();
    });

    tearDown(() async {
      client.close();
      await server.close(force: true);
    });

    test(
      'fetchSha256ForAsset reads the entry from a SHA256SUMS file',
      () async {
        final good = utf8.encode('fixture-bytes');
        final sums = '${_sha(good)}  app_1.0_amd64.deb\n';
        server = await _startServer((req) async {
          if (req.uri.path == '/SHA256SUMS') {
            _respond(req, 200, utf8.encode(sums));
          } else {
            _respond(req, 404, utf8.encode('nope'));
          }
        });
        expect(
          await fetchSha256ForAsset(
            client: client,
            sumsUrl: _url(server, '/SHA256SUMS').toString(),
            assetName: 'app_1.0_amd64.deb',
          ),
          _sha(good),
        );
        expect(
          await fetchSha256ForAsset(
            client: client,
            sumsUrl: _url(server, '/SHA256SUMS').toString(),
            assetName: 'other.deb',
          ),
          isNull,
        );
        expect(
          await fetchSha256ForAsset(
            client: client,
            sumsUrl: _url(server, '/missing').toString(),
            assetName: 'app_1.0_amd64.deb',
          ),
          isNull,
        );
        expect(
          await fetchSha256ForAsset(
            client: client,
            sumsUrl: null,
            assetName: 'app_1.0_amd64.deb',
          ),
          isNull,
        );
      },
    );

    test('fetchSha256FromUrl reads a single-hash .sha256 file', () async {
      final hex = 'a' * 64;
      server = await _startServer((req) async {
        if (req.uri.path == '/pkg.sha256') {
          _respond(req, 200, utf8.encode('$hex  Tailscale-1.0-macos.pkg\n'));
        } else {
          _respond(req, 404, utf8.encode('nope'));
        }
      });
      expect(
        await fetchSha256FromUrl(
          client: client,
          url: _url(server, '/pkg.sha256'),
        ),
        hex,
      );
      expect(
        await fetchSha256FromUrl(
          client: client,
          url: _url(server, '/gone.sha256'),
        ),
        isNull,
      );
    });

    test('resolveRedirectTarget follows one redirect, nothing else', () async {
      server = await _startServer((req) async {
        if (req.uri.path == '/latest') {
          req.response.statusCode = 302;
          req.response.headers.set(
            'location',
            'https://example.invalid/stable/Tailscale-1.2.3-macos.pkg',
          );
          await req.response.close();
        } else if (req.uri.path == '/plain') {
          _respond(req, 200, utf8.encode('body'));
        } else {
          req.response.statusCode = 302;
          await req.response.close();
        }
      });
      expect(
        await resolveRedirectTarget(
          client: client,
          url: _url(server, '/latest'),
        ),
        Uri.parse('https://example.invalid/stable/Tailscale-1.2.3-macos.pkg'),
      );
      expect(
        await resolveRedirectTarget(
          client: client,
          url: _url(server, '/plain'),
        ),
        isNull,
      );
      expect(
        await resolveRedirectTarget(
          client: client,
          url: _url(server, '/no-location'),
        ),
        isNull,
      );
    });
  });

  group('VerifySha256.verifyFileOrDelete', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('fpai_verify_');
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    Future<File> fixture(List<int> bytes) async {
      final file = File('${dir.path}/artifact.bin');
      await file.writeAsBytes(bytes);
      return file;
    }

    test('matching hash passes and keeps the file', () async {
      final bytes = utf8.encode('real bytes');
      final file = await fixture(bytes);
      await VerifySha256.verifyFileOrDelete(
        file,
        _sha(bytes),
        assetLabel: 'test artifact',
      );
      expect(await file.exists(), isTrue);
    });

    test('mismatched hash throws and deletes the file', () async {
      final file = await fixture(utf8.encode('tampered bytes'));
      await expectLater(
        VerifySha256.verifyFileOrDelete(
          file,
          _sha(utf8.encode('real bytes')),
          assetLabel: 'test artifact',
        ),
        throwsA(isA<StateError>()),
      );
      expect(await file.exists(), isFalse);
    });

    test('missing hash throws and deletes the file', () async {
      for (final missing in <String?>[null, '']) {
        final file = await fixture(utf8.encode('bytes'));
        await expectLater(
          VerifySha256.verifyFileOrDelete(
            file,
            missing,
            assetLabel: 'test artifact',
          ),
          throwsA(isA<StateError>()),
        );
        expect(await file.exists(), isFalse);
      }
    });
  });

  group('self-update verification entry point', () {
    late Directory dir;
    late HttpServer server;
    late http.Client client;

    const assetName = 'front-porch-ai_1.5.0_alice7_amd64.deb';
    final goodBytes = utf8.encode('installer-bytes');
    final goodHex = _sha(goodBytes);

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('fpai_update_verify_');
      client = http.Client();
      server = await _startServer((req) async {
        if (req.uri.path == '/SHA256SUMS') {
          _respond(req, 200, utf8.encode('$goodHex  $assetName\n'));
        } else {
          _respond(req, 404, utf8.encode('nope'));
        }
      });
    });

    tearDown(() async {
      client.close();
      await server.close(force: true);
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    Future<File> staged(List<int> bytes) async {
      final file = File('${dir.path}/$assetName');
      await file.writeAsBytes(bytes);
      return file;
    }

    test('matching bytes against the published sums pass and stage', () async {
      final file = await staged(goodBytes);
      await verifyStagedUpdateInstaller(
        file: file,
        assetName: assetName,
        sha256SumsUrl: _url(server, '/SHA256SUMS').toString(),
        client: client,
      );
      expect(await file.exists(), isTrue);
    });

    test('tampered bytes are blocked and deleted', () async {
      final file = await staged(utf8.encode('tampered installer'));
      await expectLater(
        verifyStagedUpdateInstaller(
          file: file,
          assetName: assetName,
          sha256SumsUrl: _url(server, '/SHA256SUMS').toString(),
          client: client,
        ),
        throwsA(isA<StateError>()),
      );
      expect(await file.exists(), isFalse);
    });

    test('missing SHA256SUMS blocks and deletes', () async {
      final file = await staged(goodBytes);
      await expectLater(
        verifyStagedUpdateInstaller(
          file: file,
          assetName: assetName,
          sha256SumsUrl: _url(server, '/no-such-file').toString(),
          client: client,
        ),
        throwsA(isA<StateError>()),
      );
      expect(await file.exists(), isFalse);
    });

    test('no checksum source at all blocks and deletes', () async {
      final file = await staged(goodBytes);
      await expectLater(
        verifyStagedUpdateInstaller(
          file: file,
          assetName: assetName,
          sha256SumsUrl: null,
          client: client,
        ),
        throwsA(isA<StateError>()),
      );
      expect(await file.exists(), isFalse);
    });
  });

  group('KoboldCpp verification entry point', () {
    late Directory dir;
    late HttpServer server;
    late http.Client client;

    const assetName = 'koboldcpp-linux-x64-nocuda';
    final goodBytes = utf8.encode('engine-bytes');
    final goodHex = _sha(goodBytes);

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('fpai_kobold_verify_');
      client = http.Client();
      server = await _startServer((req) async {
        if (req.uri.path == '/SHA256SUMS') {
          _respond(req, 200, utf8.encode('$goodHex  $assetName\n'));
        } else {
          _respond(req, 404, utf8.encode('nope'));
        }
      });
    });

    tearDown(() async {
      client.close();
      await server.close(force: true);
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    Future<File> staged(List<int> bytes) async {
      final file = File('${dir.path}/$assetName.part');
      await file.writeAsBytes(bytes);
      return file;
    }

    test('matching bytes against the published sums pass', () async {
      final file = await staged(goodBytes);
      await verifyStagedKoboldEngine(
        file: file,
        assetName: assetName,
        sha256SumsUrl: _url(server, '/SHA256SUMS').toString(),
        client: client,
      );
      expect(await file.exists(), isTrue);
    });

    test('tampered bytes are blocked and the .part file is deleted', () async {
      final file = await staged(utf8.encode('tampered engine'));
      await expectLater(
        verifyStagedKoboldEngine(
          file: file,
          assetName: assetName,
          sha256SumsUrl: _url(server, '/SHA256SUMS').toString(),
          client: client,
        ),
        throwsA(isA<StateError>()),
      );
      expect(await file.exists(), isFalse);
    });

    test('no published hash blocks and deletes the .part file', () async {
      // This is the live upstream state: the release publishes no hash asset.
      final file = await staged(goodBytes);
      await expectLater(
        verifyStagedKoboldEngine(
          file: file,
          assetName: assetName,
          sha256SumsUrl: null,
          client: client,
        ),
        throwsA(isA<StateError>()),
      );
      expect(await file.exists(), isFalse);
    });
  });

  group('DownloadManager real SHA-256', () {
    late Directory dir;
    late HttpServer server;
    late DownloadManager manager;

    final fixture = utf8.encode('model fixture bytes, not a hash of prefixes');
    late String fixtureHex;

    setUp(() async {
      fixtureHex = _sha(fixture);
      dir = await Directory.systemTemp.createTemp('fpai_dm_verify_');
      server = await _startServer((req) async {
        _respond(req, 200, fixture);
      });
      manager = DownloadManager(targetDir: dir.path);
    });

    tearDown(() async {
      manager.dispose();
      await server.close(force: true);
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('matching expected hash completes the download', () async {
      final task = manager.addDownload(
        url: _url(server, '/model.gguf').toString(),
        filename: 'model.gguf',
        expectedSha256: fixtureHex,
      );
      await _waitForTask(
        task,
        () => task.state == DownloadTaskState.completed,
        what: 'matching-hash download to complete',
      );
      expect(task.errorMessage, isNull);
      final target = File('${dir.path}/model.gguf');
      expect(await target.exists(), isTrue);
      expect(await target.readAsBytes(), fixture);
    });

    test('mismatched expected hash fails the download', () async {
      final task = manager.addDownload(
        url: _url(server, '/model.gguf').toString(),
        filename: 'model.gguf',
        expectedSha256: _sha(utf8.encode('different bytes entirely')),
      );
      await _waitForTask(
        task,
        () => task.state == DownloadTaskState.failed,
        what: 'mismatched-hash download to fail',
      );
      expect(task.errorMessage, contains('SHA256 mismatch'));
      // Never promoted to the finished location.
      expect(await File('${dir.path}/model.gguf').exists(), isFalse);
    });
  });
}
