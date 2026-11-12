// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/services/opencode/opencode.dart';
import 'package:path/path.dart' as p;

const _latestTag = '1.19.99';

Future<({String tag, int? assetBytes})?> _latestLookup() async =>
    (tag: _latestTag, assetBytes: 44 * 1024 * 1024);

/// Places a binary and version stamp in the closet the way a successful
/// install would, so lifecycle tests (start / stop / ensure) can run
/// without downloading. No hash is involved: the guard only runs on an
/// install attempt, and these tests make none.
Future<void> _seedInstalledBinary(
  OpenCodeManager mgr, {
  String version = _latestTag,
  String contents = 'SEEDED',
}) async {
  await mgr.closet.ensureLayout();
  await File(mgr.closet.binaryPath).writeAsString(contents);
  await OpenCodeBinaryVersion.write(
    mgr.closet.binDir,
    version: version,
    size: contents.length,
  );
  await mgr.refreshInstalled();
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('fpai_oc_mgr_');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'closet lives under the storage root, not brew or ~/.config/opencode',
    () {
      final closet = OpenCodeCloset(root.path);
      expect(closet.binDir, p.join(root.path, 'opencode-bin'));
      expect(closet.binaryPath, startsWith(closet.binDir));
      expect(openCodeLooksLikeBrewPath(closet.binaryPath), isFalse);
      expect(openCodeLooksLikeUserConfigPath(closet.configFilePath), isFalse);
      expect(
        closet.configFilePath,
        isNot(contains('${p.separator}.config${p.separator}opencode')),
      );
    },
  );

  test('isolated env points only at the closet', () {
    final closet = OpenCodeCloset(root.path);
    final env = openCodeIsolatedEnvironment(closet);
    expect(env['OPENCODE_CONFIG'], closet.configFilePath);
    expect(env['OPENCODE_CONFIG_DIR'], closet.configDir);
    expect(env['OPENCODE_DATA_DIR'], closet.dataDir);
    expect(env['OPENCODE_DISABLE_GLOBAL_CONFIG'], 'true');
    for (final value in env.values) {
      expect(openCodeLooksLikeBrewPath(value), isFalse);
      expect(openCodeLooksLikeUserConfigPath(value), isFalse);
    }
  });

  test('voice plugin sits beside opencode.json, not config/plugins', () async {
    final closet = OpenCodeCloset(root.path);
    await closet.ensureLayout();
    final stale = File(openCodeVoicePluginStalePath(closet));
    await stale.parent.create(recursive: true);
    await stale.writeAsString('old-double-load-copy');
    expect(await writeOpenCodeVoicePluginFile(closet), isTrue);
    expect(await File(openCodeVoicePluginPath(closet)).exists(), isTrue);
    expect(
      openCodeVoicePluginPath(closet),
      isNot(contains('${p.separator}plugins${p.separator}')),
    );
    expect(await stale.exists(), isFalse);
    expect(await writeOpenCodeVoicePluginFile(closet), isFalse);
  });

  // Finding 3: a release that publishes no SHA-256 must fail closed.
  // Fake tag 1.19.99 has no GitHub release, so there is no hash to check
  // against — the download still happens (the bytes must be fetched before
  // they can be verified), but nothing is unpacked, installed, or stamped.
  test('ensureInstalled refuses without a published SHA-256', () async {
    final captured = <Uri>[];
    var unpacks = 0;
    final mgr = OpenCodeManager(
      rootPath: root.path,
      remoteLookup: _latestLookup,
      downloader: (url, {onProgress}) async {
        captured.add(url);
        onProgress?.call(12, 12);
        return utf8.encode('zip-bytes');
      },
      unpack: (bytes, dest) async {
        unpacks++;
        final bin = File(
          p.join(dest.path, OpenCodeCloset(root.path).binaryName),
        );
        await bin.writeAsString('FAKE-OPENCODE');
        return bin;
      },
    );

    await expectLater(
      mgr.ensureInstalled(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('No published SHA-256 for OpenCode $_latestTag'),
        ),
      ),
    );

    expect(captured, hasLength(1));
    expect(
      captured.single.toString(),
      contains('/releases/download/v$_latestTag/'),
    );
    expect(captured.single.toString(), isNot(contains('latest/download')));
    expect(unpacks, 0);
    expect(await mgr.isInstalled, isFalse);
    expect(mgr.installedVersion, isNull);
    expect(mgr.error, contains('No published SHA-256'));
    expect(openCodeLooksLikeBrewPath(mgr.closet.binaryPath), isFalse);
  });

  test(
    'ensureInstalled does not re-download when a binary is already there',
    () async {
      var downloads = 0;
      final mgr = OpenCodeManager(
        rootPath: root.path,
        remoteLookup: _latestLookup,
        downloader: (url, {onProgress}) async {
          downloads++;
          return utf8.encode('zip');
        },
        unpack: (bytes, dest) async {
          final bin = File(
            p.join(dest.path, OpenCodeCloset(root.path).binaryName),
          );
          await bin.writeAsString('ONCE');
          return bin;
        },
      );
      // A binary already in the closet means there is nothing to install,
      // so ensureInstalled must return early without downloading at all.
      await _seedInstalledBinary(mgr, contents: 'ONCE');
      await mgr.ensureInstalled();
      await mgr.ensureInstalled();
      expect(downloads, 0);
      expect(File(mgr.closet.binaryPath).readAsStringSync(), 'ONCE');
      expect(mgr.installedVersion, _latestTag);
    },
  );

  test(
    'start serves 127.0.0.1 from the closet binary with isolated env',
    () async {
      const port = 18977;
      final healthHits = <Uri>[];
      OpenCodeSpawnRequest? spawned;
      final mgr = OpenCodeManager(
        rootPath: root.path,
        remoteLookup: _latestLookup,
        downloader: (url, {onProgress}) async => utf8.encode('zip'),
        unpack: (bytes, dest) async {
          final bin = File(
            p.join(dest.path, OpenCodeCloset(root.path).binaryName),
          );
          await bin.writeAsString('BIN');
          return bin;
        },
        pickPort: () async => port,
        healthGet: (base) async {
          healthHits.add(base);
          return (healthy: true, version: '1.18.30');
        },
        spawn: (req) async {
          spawned = req;
          return OpenCodeProcessHandle.fake(pid: 4242);
        },
      );

      await _seedInstalledBinary(mgr, contents: 'BIN');

      await mgr.start();

      expect(mgr.isRunning, isTrue);
      expect(mgr.baseUri.host, '127.0.0.1');
      expect(mgr.baseUri.port, port);
      expect(healthHits, isNotEmpty);
      expect(healthHits.first.port, port);
      expect(spawned, isNotNull);
      expect(spawned!.executable, mgr.closet.binaryPath);
      expect(
        spawned!.arguments,
        containsAll(['serve', '--hostname', '127.0.0.1', '--log-level']),
      );
      expect(spawned!.arguments, isNot(contains('--pure')));
      expect(spawned!.logPath, mgr.closet.serveLogPath);
      expect(spawned!.environment['OPENCODE_LOG_DIR'], mgr.closet.logDir);
      expect(
        spawned!.environment['OPENCODE_CONFIG'],
        mgr.closet.configFilePath,
      );
      expect(openCodeLooksLikeBrewPath(spawned!.executable), isFalse);
      expect(
        spawned!.environment['OPENCODE_CONFIG'],
        isNot(contains('${p.separator}.config${p.separator}opencode')),
      );

      await mgr.stop();
      expect(mgr.isRunning, isFalse);
    },
  );

  test('stop kills only the handle we spawned', () async {
    var killed = 0;
    final mgr = OpenCodeManager(
      rootPath: root.path,
      remoteLookup: _latestLookup,
      downloader: (url, {onProgress}) async => utf8.encode('zip'),
      unpack: (bytes, dest) async {
        final bin = File(
          p.join(dest.path, OpenCodeCloset(root.path).binaryName),
        );
        await bin.writeAsString('BIN');
        return bin;
      },
      pickPort: () async => 18978,
      healthGet: (base) async => (healthy: true, version: '1.18.30'),
      spawn: (req) async =>
          OpenCodeProcessHandle.fake(pid: 99, onKill: () => killed++),
    );
    // Start needs a binary in the closet; with no published hash an
    // install attempt would fail closed, so seed one instead.
    await _seedInstalledBinary(mgr, contents: 'BIN');
    await mgr.start();
    await mgr.stop();
    expect(killed, 1);
  });

  test(
    'stale stamp does not re-download on ensure; upgrade refuses without a published SHA-256',
    () async {
      var downloads = 0;
      var unpacks = 0;
      final mgr = OpenCodeManager(
        rootPath: root.path,
        remoteLookup: _latestLookup,
        downloader: (url, {onProgress}) async {
          downloads++;
          return utf8.encode('zip');
        },
        unpack: (bytes, dest) async {
          unpacks++;
          final bin = File(
            p.join(dest.path, OpenCodeCloset(root.path).binaryName),
          );
          await bin.writeAsString('PIN');
          return bin;
        },
      );
      // Seed the closet as if 1.0.0 were installed: ensureInstalled must
      // leave it alone, and an upgrade attempt must fail closed — fake tag
      // 1.19.99 publishes no hash, so the bytes are downloaded but never
      // unpacked and the installed version does not move.
      await _seedInstalledBinary(mgr, version: '1.0.0', contents: 'PIN');
      await mgr.refreshInstalled();
      expect(mgr.installedVersion, '1.0.0');
      // Seeding never looks up the remote version; check it (no download)
      // so isUpdateAvailable can compare installed 1.0.0 against 1.19.99.
      await mgr.checkRemoteVersion();
      expect(mgr.isUpdateAvailable, isTrue);
      await mgr.ensureInstalled();
      expect(downloads, 0);
      await expectLater(
        mgr.upgrade(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('No published SHA-256 for OpenCode $_latestTag'),
          ),
        ),
      );
      expect(downloads, 1);
      expect(unpacks, 0);
      expect(mgr.installedVersion, '1.0.0');
      expect(mgr.isUpdateAvailable, isTrue);
      expect(mgr.error, contains('No published SHA-256'));
      expect(File(mgr.closet.binaryPath).readAsStringSync(), 'PIN');
    },
  );

  test(
    'checkRemoteVersion records GitHub latest and never downloads',
    () async {
      var downloads = 0;
      final mgr = OpenCodeManager(
        rootPath: root.path,
        downloader: (url, {onProgress}) async {
          downloads++;
          return utf8.encode('zip');
        },
        remoteLookup: () async =>
            (tag: '1.19.99', assetBytes: 44 * 1024 * 1024),
      );
      await mgr.checkRemoteVersion();
      expect(mgr.remoteVersion, '1.19.99');
      expect(downloads, 0);
      expect(mgr.isUpdateAvailable, isTrue);
    },
  );

  test(
    'upgrade stops a running serve then refuses without a published SHA-256',
    () async {
      var killed = 0;
      var downloads = 0;
      var unpacks = 0;
      final mgr = OpenCodeManager(
        rootPath: root.path,
        remoteLookup: _latestLookup,
        downloader: (url, {onProgress}) async {
          downloads++;
          return utf8.encode('zip');
        },
        unpack: (bytes, dest) async {
          unpacks++;
          final bin = File(
            p.join(dest.path, OpenCodeCloset(root.path).binaryName),
          );
          await bin.writeAsString('NEW');
          return bin;
        },
        pickPort: () async => 18979,
        healthGet: (base) async => (healthy: true, version: '1.18.30'),
        spawn: (req) async =>
            OpenCodeProcessHandle.fake(pid: 7, onKill: () => killed++),
      );
      await _seedInstalledBinary(mgr, contents: 'NEW');
      await mgr.start();
      expect(mgr.isRunning, isTrue);
      await OpenCodeBinaryVersion.write(
        mgr.closet.binDir,
        version: '1.0.0',
        size: 1,
      );
      await mgr.refreshInstalled();
      // Seeding never looks up the remote version; check it (no download)
      // so isUpdateAvailable can compare installed 1.0.0 against 1.19.99.
      await mgr.checkRemoteVersion();
      expect(mgr.isUpdateAvailable, isTrue);
      // The serve is stopped first, then the install attempt fails closed:
      // fake tag 1.19.99 publishes no hash, so nothing is unpacked and
      // the installed version stays at the stale stamp.
      await expectLater(
        mgr.upgrade(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('No published SHA-256 for OpenCode $_latestTag'),
          ),
        ),
      );
      expect(killed, greaterThanOrEqualTo(1));
      expect(downloads, 1);
      expect(unpacks, 0);
      expect(mgr.isRunning, isFalse);
      expect(mgr.installedVersion, '1.0.0');
      expect(mgr.error, contains('No published SHA-256'));
    },
  );
}
