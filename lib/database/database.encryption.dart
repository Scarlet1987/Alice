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

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:front_porch_ai/services/security/file_permissions.dart';
import 'package:front_porch_ai/services/storage/secure_credential_store.dart';

/// Secure-store key under which the database encryption key lives.
/// The stored value is a fresh random 256-bit key, base64-encoded, generated
/// exactly once by [SecureCredentialStore.getOrCreateKey].
const String dbEncryptionKeyName = 'alice.db.encryption_key';

/// The database could not be opened, verified, or migrated as an encrypted
/// database. Callers fail closed on this: never open the file as plaintext
/// instead — a silent plaintext fallback would defeat the encryption.
class DatabaseEncryptionException implements Exception {
  const DatabaseEncryptionException(this.message);

  final String message;

  @override
  String toString() => 'DatabaseEncryptionException: $message';
}

/// The SQLite file header of an unencrypted database.
const _plaintextHeader = <int>[
  0x53, // S
  0x51, // Q
  0x4C, // L
  0x69, // i
  0x74, // t
  0x65, // e
  0x20, // space
  0x66, // f
  0x6F, // o
  0x72, // r
  0x6D, // m
  0x61, // a
  0x74, // t
  0x20, // space
  0x33, // 3
  0x00, // NUL
];

/// Reads the stored database key, generating and storing a fresh random
/// 256-bit key on first use. A secure-store failure throws
/// [SecureCredentialStoreException]; callers surface it, never fall back to
/// an unencrypted database.
Future<String> loadDatabaseKey() async {
  final store = await SecureCredentialStore.open();
  return store.getOrCreateKey(dbEncryptionKeyName);
}

/// True when [file] is an existing, non-empty, unencrypted SQLite database
/// (its first 16 bytes are the `SQLite format 3` header). An encrypted file
/// starts with random salt bytes, so it never matches; a missing or empty
/// file is fresh, not plaintext.
bool isPlaintextDatabase(File file) {
  if (!file.existsSync()) return false;
  final raf = file.openSync();
  try {
    if (raf.lengthSync() < _plaintextHeader.length) return false;
    final header = raf.readSync(_plaintextHeader.length);
    for (var i = 0; i < _plaintextHeader.length; i++) {
      if (header[i] != _plaintextHeader[i]) return false;
    }
    return true;
  } finally {
    raf.closeSync();
  }
}

/// The stored base64 key as a SQLCipher raw-key literal, ` "x'<hex>'" `.
/// A malformed stored value throws [DatabaseEncryptionException] instead of
/// being reinterpreted as a passphrase — the key must be exactly the 32
/// random bytes [loadDatabaseKey] generated.
String _keyLiteral(String base64Key) {
  final List<int> bytes;
  try {
    bytes = base64.decode(base64Key.trim());
  } on FormatException {
    throw const DatabaseEncryptionException(
      'The stored database key is malformed. The database cannot be '
      'opened.',
    );
  }
  if (bytes.length != 32) {
    throw const DatabaseEncryptionException(
      'The stored database key is malformed. The database cannot be '
      'opened.',
    );
  }
  final hex = StringBuffer();
  for (final b in bytes) {
    hex.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return '"x\'${hex.toString()}\'"';
}

String _escape(String value) => value.replaceAll("'", "''");

/// True when the linked SQLite library is SQLCipher. Plain SQLite answers
/// `PRAGMA cipher_version` with zero rows; SQLCipher answers one row with
/// its version. Checking this is what stops a misconfigured build from
/// silently writing plaintext databases.
bool _hasCipher(Database db) {
  try {
    return db.select('PRAGMA cipher_version;').isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Applies the encryption key (and the existing `synchronous = FULL`
/// setting) to a freshly opened connection, then proves the key by reading
/// the schema. Runs in Drift's `setup` callback, before Drift touches the
/// database in any way, and in the pre-open probe below. A wrong key or a
/// non-SQLCipher library throws [DatabaseEncryptionException].
void setupEncryptedConnection(Database db, String base64Key) {
  if (!_hasCipher(db)) {
    throw const DatabaseEncryptionException(
      'This build has no SQLCipher support (PRAGMA cipher_version is '
      'empty). Refusing to open the database unencrypted.',
    );
  }
  final keyLiteral = _keyLiteral(base64Key);
  try {
    db.execute('PRAGMA key = $keyLiteral;');
    // Any statement that touches the file throws here on a wrong key or a
    // corrupt file (SQLCipher verifies the page HMAC on first read), so the
    // whole apply-and-probe sequence is one guarded block — catching only
    // the final SELECT would miss failures from the PRAGMAs above it.
    db.execute('PRAGMA synchronous = FULL');
    db.select('SELECT count(*) FROM sqlite_master;');
  } on SqliteException {
    throw const DatabaseEncryptionException(
      'Could not open the database with the stored key. The file may be '
      'corrupt or encrypted with a different key.',
    );
  }
  debugPrint('[DB] SQLCipher encryption active');
}

/// Makes sure [file] is an encrypted database openable with [base64Key]:
/// a missing or empty file is fresh (Drift's setup encrypts it on first
/// write); a plaintext file is migrated in place; an encrypted file is
/// probed with the key. A failed probe or migration throws
/// [DatabaseEncryptionException] and leaves the original file untouched.
///
/// When [expectedSchemaVersion] is given (the app's current Drift schema
/// version), an encrypted database stuck at user_version 0 that already
/// holds tables is repaired to that version. That state can only come from
/// the first encryption migration, which lost user_version (see
/// [_migratePlaintextToEncrypted]): Drift would otherwise run its
/// fresh-install path and die on the bare CREATE INDEX for an index the
/// export already copied. A genuinely fresh database has no tables, so it
/// is never repaired. Callers that open copies without Drift (backups,
/// reunification temps) omit the parameter and get no repair.
Future<void> ensureDatabaseEncrypted(
  File file,
  String base64Key, {
  int? expectedSchemaVersion,
}) async {
  if (!await file.exists()) return;
  if (await file.length() == 0) return;
  if (isPlaintextDatabase(file)) {
    await _migratePlaintextToEncrypted(file, base64Key);
    return;
  }
  final db = sqlite3.open(file.path);
  try {
    setupEncryptedConnection(db, base64Key);
    if (expectedSchemaVersion != null) {
      _repairLostUserVersion(db, expectedSchemaVersion);
    }
  } finally {
    db.close();
  }
}

/// Heals a database whose schema version was lost by the first encryption
/// migration: user_version 0 with real tables. Sets it to
/// [expectedSchemaVersion] so Drift runs upgrades (or none) instead of its
/// fresh-install path. Never touches a database with a version already set,
/// or one with no tables at all.
void _repairLostUserVersion(Database db, int expectedSchemaVersion) {
  final version =
      db.select('PRAGMA user_version;').first['user_version'] as int;
  if (version != 0) return;
  final tables = db
      .select(
        "SELECT count(*) AS n FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%';",
      )
      .first['n'] as int;
  if (tables == 0) return;
  debugPrint(
    '[DB] Repairing lost schema version (0 -> $expectedSchemaVersion) '
    'on an encrypted database with $tables tables.',
  );
  db.execute('PRAGMA user_version = $expectedSchemaVersion;');
}

/// Converts a plaintext database to SQLCipher in place, without losing user
/// data. The export is verified before the swap, and the swap is a single
/// atomic rename of the verified encrypted copy over the original (same
/// directory, same filesystem), so a crash leaves either the old plaintext
/// file or the new encrypted file — never a half-written database, and never
/// neither. Any failure before the rename leaves the original untouched.
Future<void> _migratePlaintextToEncrypted(File file, String base64Key) async {
  final tmpPath = '${file.path}.encrypting';
  final tmp = File(tmpPath);
  try {
    if (await tmp.exists()) await tmp.delete();
  } catch (_) {}

  try {
    // sqlcipher_export copies schema and data but NOT PRAGMA user_version,
    // which is where Drift keeps its schema version. Read it now: without
    // it the encrypted copy looks brand-new (version 0) to Drift, which
    // runs its fresh-install path and dies on the bare CREATE INDEX for an
    // index the export already copied.
    var sourceUserVersion = 0;
    final plain = sqlite3.open(file.path);
    try {
      if (!_hasCipher(plain)) {
        throw const DatabaseEncryptionException(
          'This build has no SQLCipher support (PRAGMA cipher_version is '
          'empty). Refusing to migrate the database.',
        );
      }
      sourceUserVersion =
          plain.select('PRAGMA user_version;').first['user_version'] as int;
      // Checkpoint any WAL so no -wal/-shm sidecar survives the swap and
      // gets replayed against the encrypted file.
      try {
        plain.execute('PRAGMA wal_checkpoint(TRUNCATE);');
      } catch (_) {}
      plain.execute(
        "ATTACH '${_escape(tmpPath)}' AS encrypted "
        'KEY ${_keyLiteral(base64Key)};',
      );
      try {
        plain.execute("SELECT sqlcipher_export('encrypted');");
      } finally {
        plain.execute('DETACH encrypted;');
      }
    } finally {
      plain.close();
    }

    _verifyEncryptedCopy(source: file, copy: tmp, base64Key: base64Key);

    // Write the preserved version onto the verified copy before the swap.
    final copyDb = sqlite3.open(tmp.path);
    try {
      setupEncryptedConnection(copyDb, base64Key);
      copyDb.execute('PRAGMA user_version = $sourceUserVersion;');
    } finally {
      copyDb.close();
    }

    await tmp.rename(file.path);
    await FilePermissions.hardenFile(file);
    await _deleteSidecars(file);
  } on DatabaseEncryptionException {
    await _deleteIfExists(tmp);
    rethrow;
  } catch (e) {
    await _deleteIfExists(tmp);
    throw DatabaseEncryptionException(
      'Database encryption migration failed, original left untouched: $e',
    );
  }
}

/// The exported copy must open with the key, hold the same schema, pass
/// integrity check, and not be a plaintext file. Runs before the atomic
/// swap, so a bad export never replaces the original.
void _verifyEncryptedCopy({
  required File source,
  required File copy,
  required String base64Key,
}) {
  if (!copy.existsSync() || isPlaintextDatabase(copy)) {
    throw const DatabaseEncryptionException(
      'Encryption migration produced no encrypted file.',
    );
  }
  final Set<String> sourceSchema;
  final sourceDb = sqlite3.open(source.path);
  try {
    sourceSchema = {
      for (final row in sourceDb.select('SELECT name FROM sqlite_master;'))
        row['name'] as String,
    };
  } finally {
    sourceDb.close();
  }
  final db = sqlite3.open(copy.path);
  try {
    setupEncryptedConnection(db, base64Key);
    final copySchema = {
      for (final row in db.select('SELECT name FROM sqlite_master;'))
        row['name'] as String,
    };
    if (copySchema.length != sourceSchema.length ||
        !copySchema.containsAll(sourceSchema)) {
      throw const DatabaseEncryptionException(
        'Encryption migration lost schema entries. Original left untouched.',
      );
    }
    final check = db.select('PRAGMA integrity_check;');
    if (check.isEmpty || check.first.values.first != 'ok') {
      throw const DatabaseEncryptionException(
        'Encryption migration failed integrity check. Original left '
        'untouched.',
      );
    }
  } finally {
    db.close();
  }
}

Future<void> _deleteIfExists(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } catch (_) {}
}

/// Drops WAL/SHM/journal sidecars next to [file] after a migration swap.
/// They belong to the pre-swap file; replaying one against the encrypted
/// file would corrupt it.
Future<void> _deleteSidecars(File file) async {
  await _deleteIfExists(File('${file.path}-wal'));
  await _deleteIfExists(File('${file.path}-shm'));
  await _deleteIfExists(File('${file.path}-journal'));
}
