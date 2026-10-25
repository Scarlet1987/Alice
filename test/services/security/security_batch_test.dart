// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/models/download_task.dart';
import 'package:front_porch_ai/services/security/file_permissions.dart';
import 'package:front_porch_ai/services/security/verify_sha256.dart';

void main() {
  group('VerifySha256', () {
    test('verifyFile matches correct hash', () async {
      final tmp = await Directory.systemTemp.createTemp('vsha_test_');
      try {
        final file = File('${tmp.path}/data.bin');
        await file.writeAsBytes([1, 2, 3, 4, 5]);
        final expected = sha256.convert([1, 2, 3, 4, 5]).toString();
        expect(await VerifySha256.verifyFile(file, expected), isTrue);
        expect(await VerifySha256.verifyFile(file, expected.toUpperCase()),
            isTrue);
      } finally {
        await tmp.delete(recursive: true);
      }
    });

    test('verifyFile rejects wrong hash', () async {
      final tmp = await Directory.systemTemp.createTemp('vsha_test_');
      try {
        final file = File('${tmp.path}/data.bin');
        await file.writeAsBytes([1, 2, 3, 4, 5]);
        expect(await VerifySha256.verifyFile(file, '0' * 64), isFalse);
      } finally {
        await tmp.delete(recursive: true);
      }
    });

    test('verifyBytes matches and rejects', () {
      final bytes = [10, 20, 30];
      final expected = sha256.convert(bytes).toString();
      expect(VerifySha256.verifyBytes(bytes, expected), isTrue);
      expect(VerifySha256.verifyBytes(bytes, 'f' * 64), isFalse);
    });

    test('verifyFileOrThrow throws on mismatch', () async {
      final tmp = await Directory.systemTemp.createTemp('vsha_test_');
      try {
        final file = File('${tmp.path}/data.bin');
        await file.writeAsBytes([9, 9, 9]);
        expect(
          () => VerifySha256.verifyFileOrThrow(file, 'a' * 64,
              assetLabel: 'test'),
          throwsA(isA<StateError>()),
        );
      } finally {
        await tmp.delete(recursive: true);
      }
    });

    test('verifyFileOrThrow returns false with TODO when no hash', () async {
      final tmp = await Directory.systemTemp.createTemp('vsha_test_');
      try {
        final file = File('${tmp.path}/data.bin');
        await file.writeAsBytes([9, 9, 9]);
        expect(
          await VerifySha256.verifyFileOrThrow(file, null,
              assetLabel: 'test-no-hash'),
          isFalse,
        );
      } finally {
        await tmp.delete(recursive: true);
      }
    });
  });

  group('DownloadTask.sanitizeFilename', () {
    test('strips directory components', () {
      expect(DownloadTask.sanitizeFilename('a/b/model.gguf'), 'model.gguf');
      expect(DownloadTask.sanitizeFilename('..\\..\\evil.exe'), 'evil.exe');
    });

    test('strips traversal to safe basename', () {
      // basename strips the traversal; the result is a safe plain filename.
      expect(
          DownloadTask.sanitizeFilename('../../etc/passwd'), 'passwd');
    });

    test('rejects bare dot segments', () {
      expect(() => DownloadTask.sanitizeFilename('..'), throwsArgumentError);
      expect(() => DownloadTask.sanitizeFilename('.'), throwsArgumentError);
    });

    test('constructor sanitizes', () {
      final task = DownloadTask(
        url: 'https://example.com/x',
        filename: 'subdir/model.gguf',
        targetDir: '/tmp/models',
      );
      expect(task.filename, 'model.gguf');
      expect(task.targetPath, '/tmp/models/model.gguf');
    });
  });

  group('FilePermissions', () {
    test('hardenDir creates and hardens', () async {
      final tmp = await Directory.systemTemp.createTemp('fperm_test_');
      try {
        final dir = Directory('${tmp.path}/data');
        await FilePermissions.hardenDir(dir);
        expect(await dir.exists(), isTrue);
        if (!Platform.isWindows) {
          final stat = await FileStat.stat(dir.path);
          // 0700 = owner rwx only
          expect(stat.mode & 0x1FF, 0x1C0);
        }
      } finally {
        await tmp.delete(recursive: true);
      }
    });

    test('hardenFile restricts', () async {
      final tmp = await Directory.systemTemp.createTemp('fperm_test_');
      try {
        final file = File('${tmp.path}/secret.db');
        await file.writeAsString('x');
        await FilePermissions.hardenFile(file);
        if (!Platform.isWindows) {
          final stat = await FileStat.stat(file.path);
          expect(stat.mode & 0x1FF, 0x180);
        }
      } finally {
        await tmp.delete(recursive: true);
      }
    });
  });
}
