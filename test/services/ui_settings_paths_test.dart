// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Pins for the Settings "Where things live" folder paths on [PathSettings]:
// untouched paths resolve to their real folders under the live data root,
// a chosen folder survives a reload (app restart), and reset-all puts
// every folder back to its default.
//
// Deliberately NOT covered here: the text-model folder (driven by the
// existing StorageService.customModelsPath plumbing, tested with the model
// manager) and the character/world folders (they show the real asset
// folders; the cards themselves live in the database).

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_porch_ai/services/storage/settings/path_settings.dart';

Future<PathSettings> _loadedSettings({String dataRoot = '/data/root'}) async {
  final prefs = await SharedPreferences.getInstance();
  final settings = PathSettings();
  settings.initializeBase(prefs, () {});
  settings.dataRoot = dataRoot;
  settings.load();
  return settings;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('where-things-live path defaults', () {
    test('resolve to the real folders under the data root', () async {
      final s = await _loadedSettings();
      expect(s.imageModelsPath, path.join('/data/root', 'models', 'image'));
      // Backups default to the folder next to the database, exactly where
      // BackupService has always written them.
      expect(
        s.backupsPath,
        path.join('/data/root', 'KoboldManager', 'backups'),
      );
      expect(s.logsPath, path.join('/data/root', 'logs'));
      expect(s.pathsAreDefaults, isTrue);
      expect(s.backupsPathIsCustom, isFalse);
    });

    test('follow the data root when it moves', () async {
      final s = await _loadedSettings(dataRoot: '/elsewhere');
      expect(s.logsPath, path.join('/elsewhere', 'logs'));
      expect(
        s.backupsPath,
        path.join('/elsewhere', 'KoboldManager', 'backups'),
      );
    });
  });

  group('where-things-live persistence', () {
    test('a chosen folder survives a reload (app restart)', () async {
      final s = await _loadedSettings();
      await s.setImageModelsPath('/home/user/Pictures/AI');
      await s.setLogsPath('/var/log/alice');

      final reloaded = await _loadedSettings();
      expect(reloaded.imageModelsPath, '/home/user/Pictures/AI');
      expect(reloaded.logsPath, '/var/log/alice');
      expect(reloaded.pathsAreDefaults, isFalse);
      expect(reloaded.backupsPathIsCustom, isFalse);
      // Untouched folders still resolve to their defaults.
      expect(
        reloaded.backupsPath,
        path.join('/data/root', 'KoboldManager', 'backups'),
      );
    });

    test('clearing a folder returns it to the default', () async {
      final s = await _loadedSettings();
      await s.setBackupsPath('/mnt/backups');
      expect(s.backupsPathIsCustom, isTrue);
      await s.setBackupsPath(null);
      expect(
        s.backupsPath,
        path.join('/data/root', 'KoboldManager', 'backups'),
      );
      expect(s.backupsPathIsCustom, isFalse);
      expect(s.pathsAreDefaults, isTrue);
    });

    test('resetAllPaths clears every custom folder', () async {
      final s = await _loadedSettings();
      await s.setImageModelsPath('/mnt/image-models');
      await s.setBackupsPath('/mnt/backups');

      await s.resetAllPaths();
      expect(s.pathsAreDefaults, isTrue);

      final reloaded = await _loadedSettings();
      expect(reloaded.pathsAreDefaults, isTrue);
      expect(
        reloaded.imageModelsPath,
        path.join('/data/root', 'models', 'image'),
      );
    });
  });
}
