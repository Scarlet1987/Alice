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
// along with the Front Porch AI. If not, see <https://www.gnu.org/licenses/>.

// Regression: sqlcipher_export copies schema and data but NOT Drift's
// schema version (PRAGMA user_version). A plaintext database migrated to
// SQLCipher therefore looked brand-new (version 0) to Drift, which ran its
// fresh-install path (m.createAll) and died on the bare CREATE INDEX for
// an index the export had already copied — the "couldn't open its
// database" screen on first launch after the encryption update, on a
// database whose data was fine. The migration must preserve user_version,
// and an already-encrypted database stuck at version 0 with a real schema
// (migrated by the broken code) must be repaired to the app's schema
// version instead of bricking the launch.
//
// The key store here is an in-memory map behind
// SecureCredentialStore.debugStore, so no OS keychain is touched.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:front_porch_ai/database/database.encryption.dart';
import 'package:front_porch_ai/services/storage/secure_credential_store.dart';

late Map<String, String> _keychain;
late Directory _tmp;

void main() {
  setUp(() {
    _keychain = <String, String>{};
    SecureCredentialStore.debugStore = SecureCredentialStore(
      readKey: (key) async => _keychain[key],
      writeKey: (key, value) async => _keychain[key] = value,
      deleteKey: (key) async => _keychain.remove(key),
    );
    _tmp = Directory.systemTemp.createTempSync('fpai_enc_uv_test_');
  });

  tearDown(() async {
    SecureCredentialStore.debugStore = null;
    try {
      await _tmp.delete(recursive: true);
    } catch (_) {}
  });

  test('migration preserves PRAGMA user_version', () async {
    final key = await loadDatabaseKey();
    final file = _makePlaintextDb('legacy.db', userVersion: 42);
    expect(_readUserVersionPlain(file), 42);

    await ensureDatabaseEncrypted(file, key);

    expect(isPlaintextDatabase(file), isFalse);
    expect(_readUserVersionWithKey(file, key), 42);
    expect(_readNotesWithKey(file, key), ['alpha']);
  });

  test('already-encrypted database stuck at version 0 with a real schema '
      'is repaired to the app schema version', () async {
    final key = await loadDatabaseKey();
    // Simulate the broken migration: plaintext at version 0 with tables.
    // (The fixed migration preserves 0 here; the repair is what heals it.)
    final file = _makePlaintextDb('broken.db', userVersion: 0);
    await ensureDatabaseEncrypted(file, key);
    expect(_readUserVersionWithKey(file, key), 0);

    await ensureDatabaseEncrypted(file, key, expectedSchemaVersion: 55);

    expect(_readUserVersionWithKey(file, key), 55);
    expect(_readNotesWithKey(file, key), ['alpha']);
  });

  test('encrypted database with tables at version 0 is repaired', () async {
    final key = await loadDatabaseKey();
    final file = File('${_tmp.path}/fresh.db');
    final db = sqlite3.open(file.path);
    try {
      setupEncryptedConnection(db, key);
      db.execute('CREATE TABLE notes (id INTEGER PRIMARY KEY, body TEXT);');
    } finally {
      db.close();
    }
    // A table-bearing database at version 0 can only come from the broken
    // migration, so it is repaired like any migrated database. The
    // genuinely fresh case (no file at all) is covered below.
    await ensureDatabaseEncrypted(file, key, expectedSchemaVersion: 55);
    expect(_readUserVersionWithKey(file, key), 55);
  });

  test('missing file is left alone', () async {
    final key = await loadDatabaseKey();
    final file = File('${_tmp.path}/missing.db');
    await ensureDatabaseEncrypted(file, key, expectedSchemaVersion: 55);
    expect(file.existsSync(), isFalse);
  });
}

/// Builds a small plaintext database (no key) with a `notes` table and a
/// chosen PRAGMA user_version.
File _makePlaintextDb(String name, {int userVersion = 0}) {
  final file = File('${_tmp.path}/$name');
  final db = sqlite3.open(file.path);
  try {
    db.execute(
      'CREATE TABLE notes (id INTEGER PRIMARY KEY, body TEXT NOT NULL);',
    );
    db.execute("INSERT INTO notes (body) VALUES ('alpha');");
    db.execute('PRAGMA user_version = $userVersion;');
  } finally {
    db.close();
  }
  return file;
}

int _readUserVersionPlain(File file) {
  final db = sqlite3.open(file.path);
  try {
    return db.select('PRAGMA user_version;').first['user_version'] as int;
  } finally {
    db.close();
  }
}

int _readUserVersionWithKey(File file, String key) {
  final db = sqlite3.open(file.path);
  try {
    setupEncryptedConnection(db, key);
    return db.select('PRAGMA user_version;').first['user_version'] as int;
  } finally {
    db.close();
  }
}

List<String> _readNotesWithKey(File file, String key) {
  final db = sqlite3.open(file.path);
  try {
    setupEncryptedConnection(db, key);
    return [
      for (final row in db.select('SELECT body FROM notes ORDER BY id;'))
        row['body'] as String,
    ];
  } finally {
    db.close();
  }
}
