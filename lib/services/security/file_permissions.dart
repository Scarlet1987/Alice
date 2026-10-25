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

import 'dart:io';

/// File-permission hardening: the app stores API keys, chat databases, and
/// backups on disk. OS defaults (0644) leave them readable by every other
/// local user. These helpers lock new files to 0600 and data dirs to 0700
/// on POSIX; on Windows they best-effort the equivalent via icacls.
///
/// All calls are best-effort — a failed chmod must never break a read/write.
class FilePermissions {
  FilePermissions._();

  /// Restrict [dir] (and create it) to owner-only access.
  static Future<void> hardenDir(Directory dir) async {
    try {
      await dir.create(recursive: true);
      if (!Platform.isWindows) {
        await Process.run('chmod', [
          '700',
          dir.path,
        ]).timeout(const Duration(seconds: 5));
      }
    } catch (_) {}
  }

  /// Restrict [file] to owner-only access. Call after writing.
  static Future<void> hardenFile(File file) async {
    try {
      if (!await file.exists()) return;
      if (!Platform.isWindows) {
        await Process.run('chmod', [
          '600',
          file.path,
        ]).timeout(const Duration(seconds: 5));
      }
    } catch (_) {}
  }
}
