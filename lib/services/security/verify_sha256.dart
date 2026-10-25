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

import 'package:crypto/crypto.dart';

/// Shared artifact-integrity verification for every download→execute pipeline.
///
/// Each pipeline (self-update, KoboldCpp engine, OpenCode binary, Tailscale
/// installer) downloads a file over HTTPS and then executes it. TLS alone is
/// not integrity: a compromised release asset or MITM can swap the bytes.
/// This helper streams the file through SHA-256 and compares against the
/// expected hex digest published alongside the release.
///
/// Callers MUST refuse to execute when verification fails. Where no published
/// hash exists yet, pass null and the caller logs a TODO — the release
/// process must publish SHA256SUMS per asset.
class VerifySha256 {
  VerifySha256._();

  /// Returns true when [file]'s SHA-256 matches [expectedHex] (case-insensitive).
  /// Streams the file — safe for multi-hundred-MB installers.
  static Future<bool> verifyFile(File file, String expectedHex) async {
    final digest = await sha256.bind(file.openRead()).first;
    return _constantTimeEquals(digest.toString(), expectedHex.trim());
  }

  /// Verifies [file] against [expectedHex], throwing on mismatch.
  /// Pass null for [expectedHex] only when no published hash exists yet —
  /// logs a warning and returns false (caller must not execute).
  static Future<bool> verifyFileOrThrow(
    File file,
    String? expectedHex, {
    required String assetLabel,
  }) async {
    if (expectedHex == null || expectedHex.isEmpty) {
      // ignore: avoid_print
      print(
        '[VerifySha256] TODO: no published SHA-256 for $assetLabel — '
        'publish SHA256SUMS per release asset before executing downloads.',
      );
      return false;
    }
    if (!await verifyFile(file, expectedHex)) {
      throw StateError(
        'SHA-256 mismatch for $assetLabel — refusing to execute. '
        'The download may be corrupt or tampered with.',
      );
    }
    return true;
  }

  /// Returns true when [bytes]' SHA-256 matches [expectedHex].
  /// For in-memory downloads (OpenCode) before writing to disk.
  static bool verifyBytes(List<int> bytes, String expectedHex) {
    final digest = sha256.convert(bytes);
    return _constantTimeEquals(digest.toString(), expectedHex.trim());
  }

  /// Constant-time hex comparison to avoid timing side-channels.
  static bool _constantTimeEquals(String a, String b) {
    final x = a.toLowerCase();
    final y = b.toLowerCase();
    if (x.length != y.length) return false;
    var diff = 0;
    for (var i = 0; i < x.length; i++) {
      diff |= x.codeUnitAt(i) ^ y.codeUnitAt(i);
    }
    return diff == 0;
  }
}
