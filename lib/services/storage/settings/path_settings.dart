// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Front Porch AI is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Front Porch AI. If not, see <https://www.gnu.org/licenses/>.

import 'package:path/path.dart' as path;
import 'settings_base.dart';

/// Folder settings for the Settings "Where things live" card and the
/// Advanced paths: where the built-in image engine scans for models,
/// where automatic backups go, and where the text engine writes its
/// session log.
///
/// A null entry means "the default folder under the app data root" — the
/// getters resolve it against [dataRoot], which StorageService keeps
/// current (init, sandbox, root relocation), so a relocation moves the
/// defaults along and only an explicit Change sticks.
///
/// Deliberately NOT here: the text-model folder (StorageService's existing
/// customModelsPath plumbing persists and serves it — the Settings row
/// drives that directly instead of duplicating it) and the character /
/// world folders (cards and worlds live in the database; the Settings
/// rows show their real asset folders, read-only).
class PathSettings with SettingsBase {
  String? _imageModelsPath;
  String? _backupsPath;
  String? _logsPath;

  /// The app data root the default folders hang off. Set by StorageService
  /// whenever the root is known or changes. Never persisted — it is the
  /// convention itself, not a user choice.
  String dataRoot = '';

  /// Where Alice looks for the AI that draws your pictures. The built-in
  /// image backend scans this folder for model files.
  String get imageModelsPath =>
      _imageModelsPath ?? path.join(dataRoot, 'models', 'image');

  /// Where automatic backups are written. Defaults to the folder next to
  /// the database — the location BackupService has always used.
  String get backupsPath =>
      _backupsPath ?? path.join(dataRoot, 'KoboldManager', 'backups');

  /// True when the user pointed backups at a folder of their own.
  bool get backupsPathIsCustom => _backupsPath != null;

  /// Where the text engine's session log file is written.
  String get logsPath => _logsPath ?? path.join(dataRoot, 'logs');

  /// True when no custom folder was chosen for any path held here.
  bool get pathsAreDefaults =>
      _imageModelsPath == null && _backupsPath == null && _logsPath == null;

  void load() {
    _imageModelsPath = _readPath('paths_image_models');
    _backupsPath = _readPath('paths_backups');
    _logsPath = _readPath('paths_logs');
  }

  // Passing null (or blank) clears the choice, back to the default folder.

  String? _readPath(String key) {
    final v = prefs?.getString(k(key));
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> _writePath(String key, String? value) async {
    if (value == null) {
      await prefs?.remove(k(key));
    } else {
      await prefs?.setString(k(key), value);
    }
  }

  String? _cleanPath(String? value) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  Future<void> setImageModelsPath(String? value) async {
    final next = _cleanPath(value);
    if (_imageModelsPath == next) return;
    _imageModelsPath = next;
    await _writePath('paths_image_models', next);
    notify();
  }

  Future<void> setBackupsPath(String? value) async {
    final next = _cleanPath(value);
    if (_backupsPath == next) return;
    _backupsPath = next;
    await _writePath('paths_backups', next);
    notify();
  }

  Future<void> setLogsPath(String? value) async {
    final next = _cleanPath(value);
    if (_logsPath == next) return;
    _logsPath = next;
    await _writePath('paths_logs', next);
    notify();
  }

  /// Clear every custom folder choice at once, back to the defaults.
  Future<void> resetAllPaths() async {
    _imageModelsPath = null;
    _backupsPath = null;
    _logsPath = null;
    for (final key in const [
      'paths_image_models',
      'paths_backups',
      'paths_logs',
    ]) {
      await prefs?.remove(k(key));
    }
    notify();
  }
}
