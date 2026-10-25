// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// First-run data handling for the Alice setup wizard (alice8): detect
// existing FrontPorchAI data on a reinstall, wipe it all for a blank slate,
// or keep it via the existing legacy migration. Nothing is ever wiped or
// migrated silently — the wizard asks first and this service only acts on
// the user's explicit choice.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_porch_ai/database/data_migration_service.dart';
import 'package:front_porch_ai/database/database.dart';
import 'package:front_porch_ai/services/storage_service.dart';

/// What the reinstall scan found. [hasData] false means a genuine fresh
/// install — the wizard skips the data-choice screen entirely.
class ExistingDataSummary {
  final int characterFiles;
  final int chatFiles;
  final int worldFiles;
  final int groupFiles;
  final int modelFiles;
  final int otherFiles;
  final int dbRows;

  const ExistingDataSummary({
    this.characterFiles = 0,
    this.chatFiles = 0,
    this.worldFiles = 0,
    this.groupFiles = 0,
    this.modelFiles = 0,
    this.otherFiles = 0,
    this.dbRows = 0,
  });

  int get totalFiles =>
      characterFiles +
      chatFiles +
      worldFiles +
      groupFiles +
      modelFiles +
      otherFiles;

  bool get hasData => totalFiles > 0 || dbRows > 0;

  /// Plain-language summary for the choice screen, e.g.
  /// "12 characters, 34 chats and 5 worlds".
  String describe() {
    final parts = <String>[];
    void add(int n, String one, String many) {
      if (n > 0) parts.add('$n ${n == 1 ? one : many}');
    }

    add(characterFiles, 'character', 'characters');
    add(chatFiles, 'chat', 'chats');
    add(worldFiles, 'world', 'worlds');
    add(groupFiles, 'group chat', 'group chats');
    add(modelFiles, 'model', 'models');
    add(otherFiles, 'file', 'files');
    if (dbRows > 0 && totalFiles == 0) {
      parts.add('$dbRows saved records');
    }
    if (parts.isEmpty) return 'no existing data';
    if (parts.length == 1) return parts.first;
    return '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
  }
}

/// What the blank-slate wipe did. Counts, never contents.
class WipeReport {
  final int filesDeleted;
  final int dirsDeleted;
  final int dbRowsDeleted;
  final int prefsKeysCleared;

  /// Paths deliberately left alone (e.g. a custom models folder outside the
  /// app data folder — never the wizard's to delete).
  final List<String> leftAlone;

  /// True when the post-wipe verification walk found nothing orphaned:
  /// zero files left, zero database rows, no stray settings.
  final bool verifiedClean;

  const WipeReport({
    required this.filesDeleted,
    required this.dirsDeleted,
    required this.dbRowsDeleted,
    required this.prefsKeysCleared,
    required this.leftAlone,
    required this.verifiedClean,
  });

  String describe() {
    final parts = <String>['$filesDeleted files', '$dbRowsDeleted records'];
    if (prefsKeysCleared > 0) {
      parts.add('$prefsKeysCleared settings');
    }
    return 'Wiped ${parts.join(', ')}.'
        '${verifiedClean ? ' Verified clean.' : ' Verification found leftovers — see the log.'}';
  }
}

/// Existing-data detection, blank-slate wipe, and import for the Alice
/// setup wizard. All file work stays inside [StorageService.rootPath]; a
/// custom models folder outside it is never touched.
class WizardDataService {
  WizardDataService(this._storage);

  final StorageService _storage;

  /// Directories scanned (and wiped) for user data, with plain labels.
  /// The database file itself is handled separately — it stays open while
  /// the app runs, so a wipe clears its rows rather than deleting the file.
  List<(String label, Directory dir)> _dataDirs() {
    final s = _storage;
    final dirs = s.directories;
    return [
      ('characters', s.charactersDir),
      ('chats', s.chatsDir),
      ('worlds', s.worldsDir),
      ('groups', s.groupsDir),
      ('tools', s.toolsDir),
      ('skills', s.skillsDir),
      ('backgrounds', s.customBackgroundDir),
      ('web cache', dirs.webThumbnailCacheDir),
      ('engine', s.binDir),
    ];
  }

  bool _underRoot(Directory dir) {
    final root = _storage.rootPath;
    if (root == null) return false;
    final dirPath = p.normalize(dir.path);
    final rootPath = p.normalize(root);
    return dirPath == rootPath || p.isWithin(rootPath, dirPath);
  }

  Future<int> _countFiles(Directory dir) async {
    var count = 0;
    try {
      if (!await dir.exists()) return 0;
      await for (final e in dir.list(recursive: true, followLinks: false)) {
        if (e is File) count++;
      }
    } catch (_) {}
    return count;
  }

  /// Scan for existing user data. Cheap: file counts plus one row-count
  /// pass over the database.
  Future<ExistingDataSummary> detectExistingData() async {
    final root = _storage.rootPath;
    if (root == null) return const ExistingDataSummary();

    var characters = 0, chats = 0, worlds = 0;
    var groups = 0, models = 0, other = 0;
    for (final (label, dir) in _dataDirs()) {
      if (!_underRoot(dir)) continue;
      final n = await _countFiles(dir);
      switch (label) {
        case 'characters':
          characters = n;
        case 'chats':
          chats = n;
        case 'worlds':
          worlds = n;
        case 'groups':
          groups = n;
        case 'engine':
          other += n; // an engine binary is not user data; counts as "other"
        default:
          other += n;
      }
    }
    // A custom models folder lives outside the app data folder on purpose —
    // counted for honesty, never wiped.
    final modelsDir = _storage.modelsDir;
    if (modelsDir.path.isNotEmpty && !_underRoot(modelsDir)) {
      models = await _countFiles(modelsDir);
    } else if (_underRoot(modelsDir)) {
      models = await _countFiles(modelsDir);
    }

    var dbRows = 0;
    try {
      dbRows = await _countDbRows();
    } catch (e) {
      debugPrint('[WizardData] DB row count failed (non-fatal): $e');
    }

    final summary = ExistingDataSummary(
      characterFiles: characters,
      chatFiles: chats,
      worldFiles: worlds,
      groupFiles: groups,
      modelFiles: models,
      otherFiles: other,
      dbRows: dbRows,
    );
    debugPrint(
      '[WizardData] Existing-data scan: ${summary.totalFiles} files, '
      '${summary.dbRows} db rows (root: $root)',
    );
    return summary;
  }

  Future<int> _countDbRows() async {
    final db = AppDatabase.current;
    if (db == null) return 0;
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' "
          "AND name != 'sqlite_sequence'",
        )
        .get();
    var total = 0;
    for (final t in tables) {
      final name = t.read<String>('name');
      final rows = await db
          .customSelect('SELECT COUNT(*) AS c FROM "$name"')
          .get();
      total += rows.first.read<int>('c');
    }
    return total;
  }

  /// Import path: keep everything. The legacy JSON → database migration
  /// normally runs at boot before the wizard appears; this reuses that same
  /// [DataMigrationService] as a no-op-safe second pass rather than
  /// reinventing it. Progress is reported in plain words for the UI.
  Future<void> importExisting({
    void Function(String step, int current, int total)? onProgress,
  }) async {
    final db = AppDatabase.current;
    if (db == null) {
      debugPrint('[WizardData] Import requested but no database is open.');
      return;
    }
    debugPrint('[WizardData] Import chosen — running DataMigrationService.');
    await DataMigrationService(db).migrate(onProgress: onProgress);
    debugPrint('[WizardData] Import complete.');
  }

  /// Blank slate: delete every user file under the app data folder, clear
  /// every database row on the live connection, and clear settings — then
  /// verify nothing orphaned remains. Returns counts, never contents.
  ///
  /// The database file itself is NOT deleted: the app holds it open and
  /// captured references would break. Row deletion on the live connection
  /// leaves zero user data behind with none of that risk.
  Future<WipeReport> wipeAll({
    void Function(String message)? onProgress,
  }) async {
    final leftAlone = <String>[];
    var filesDeleted = 0, dirsDeleted = 0, dbRowsDeleted = 0;

    // 1. Database rows, on the live connection.
    onProgress?.call('Clearing saved data...');
    try {
      dbRowsDeleted = await _deleteAllRows();
    } catch (e) {
      debugPrint('[WizardData] Row wipe failed: $e');
    }
    debugPrint('[WizardData] Wipe: deleted $dbRowsDeleted database rows.');

    // 2. Files under the app data folder.
    onProgress?.call('Deleting files...');
    for (final (label, dir) in _dataDirs()) {
      if (!_underRoot(dir)) {
        debugPrint('[WizardData] Wipe: skipping $label (outside data folder)');
        continue;
      }
      try {
        if (!await dir.exists()) continue;
        final entities = await dir
            .list(recursive: true, followLinks: false)
            .toList();
        // Files first, then directories deepest-first.
        for (final e in entities.whereType<File>()) {
          try {
            await e.delete();
            filesDeleted++;
          } catch (e) {
            debugPrint('[WizardData] Wipe: could not delete file: $e');
          }
        }
        final subdirs = entities.whereType<Directory>().toList()
          ..sort((a, b) => b.path.length.compareTo(a.path.length));
        for (final d in subdirs) {
          try {
            await d.delete();
            dirsDeleted++;
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('[WizardData] Wipe: could not clear $label: $e');
      }
    }
    debugPrint(
      '[WizardData] Wipe: deleted $filesDeleted files, $dirsDeleted folders.',
    );

    // 3. Custom models folder outside the data folder: never ours to delete.
    final modelsDir = _storage.modelsDir;
    if (modelsDir.path.isNotEmpty && !_underRoot(modelsDir)) {
      leftAlone.add(modelsDir.path);
      debugPrint(
        '[WizardData] Wipe: left custom models folder alone: '
        '${modelsDir.path}',
      );
    }

    // 4. Settings (SharedPreferences). Keep only the keys the app needs to
    // keep pointing at the same data folder and to not re-ask answered
    // questions on next launch.
    onProgress?.call('Clearing settings...');
    var prefsKeysCleared = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      const keep = {
        // StorageService._rootPathKey ('root_path' / 'root_path_beta')
        'root_path',
        'root_path_beta',
        // Beta stable-import dialog answers
        'beta_stable_import_shown',
        'beta_stable_import_skipped',
        // Legacy migration bookkeeping (files are gone; no re-run wanted)
        'db_migration_complete',
        'db_migration_unimported_files',
        // The wizard's own flag (UiSettings k('alice_wizard_completed'))
        'alice_wizard_completed',
        'beta_alice_wizard_completed',
      };
      final keys = prefs.getKeys().toList();
      for (final key in keys) {
        if (keep.contains(key)) continue;
        try {
          await prefs.remove(key);
          prefsKeysCleared++;
        } catch (e) {
          debugPrint('[WizardData] Wipe: could not clear setting: $e');
        }
      }
    } catch (e) {
      debugPrint('[WizardData] Wipe: settings clear failed: $e');
    }
    debugPrint('[WizardData] Wipe: cleared $prefsKeysCleared settings.');

    // 5. Verify: walk everything again and confirm nothing orphaned remains.
    onProgress?.call('Verifying...');
    final verifiedClean = await _verifyClean();
    debugPrint(
      '[WizardData] Wipe verification: ${verifiedClean ? 'CLEAN' : 'LEFTOVERS FOUND'}',
    );

    return WipeReport(
      filesDeleted: filesDeleted,
      dirsDeleted: dirsDeleted,
      dbRowsDeleted: dbRowsDeleted,
      prefsKeysCleared: prefsKeysCleared,
      leftAlone: leftAlone,
      verifiedClean: verifiedClean,
    );
  }

  Future<int> _deleteAllRows() async {
    final db = AppDatabase.current;
    if (db == null) return 0;
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' "
          "AND name != 'sqlite_sequence'",
        )
        .get();
    final counts = <String, int>{};
    for (final t in tables) {
      final name = t.read<String>('name');
      final rows = await db
          .customSelect('SELECT COUNT(*) AS c FROM "$name"')
          .get();
      counts[name] = rows.first.read<int>('c');
    }
    await db.customStatement('PRAGMA foreign_keys=OFF');
    try {
      for (final name in counts.keys) {
        await db.customStatement('DELETE FROM "$name"');
      }
    } finally {
      await db.customStatement('PRAGMA foreign_keys=ON');
    }
    await db.customStatement('VACUUM');
    final total = counts.values.fold(0, (a, b) => a + b);
    final nonEmpty = counts.entries.where((e) => e.value > 0).toList();
    debugPrint(
      '[WizardData] Wipe: cleared $total rows across ${counts.length} tables'
      '${nonEmpty.isEmpty ? '' : ' (${nonEmpty.map((e) => '${e.key}: ${e.value}').join(', ')})'}',
    );
    return total;
  }

  Future<bool> _verifyClean() async {
    // Files.
    for (final (label, dir) in _dataDirs()) {
      if (!_underRoot(dir)) continue;
      final remaining = await _countFiles(dir);
      if (remaining > 0) {
        debugPrint('[WizardData] Verify: $remaining file(s) remain in $label.');
        return false;
      }
    }
    // Database rows.
    try {
      final rows = await _countDbRows();
      if (rows > 0) {
        debugPrint('[WizardData] Verify: $rows database row(s) remain.');
        return false;
      }
    } catch (e) {
      debugPrint('[WizardData] Verify: row recount failed: $e');
      return false;
    }
    // Settings: only the preserved keys may remain.
    try {
      final prefs = await SharedPreferences.getInstance();
      const keep = {
        'root_path',
        'root_path_beta',
        'beta_stable_import_shown',
        'beta_stable_import_skipped',
        'db_migration_complete',
        'db_migration_unimported_files',
        'alice_wizard_completed',
        'beta_alice_wizard_completed',
      };
      final stray = prefs.getKeys().where((k) => !keep.contains(k)).toList();
      if (stray.isNotEmpty) {
        debugPrint('[WizardData] Verify: ${stray.length} stray setting(s).');
        return false;
      }
    } catch (e) {
      debugPrint('[WizardData] Verify: prefs check failed: $e');
      return false;
    }
    return true;
  }
}
