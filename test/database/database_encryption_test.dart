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

// Database encryption at rest (SQLCipher): a database created through the
// encrypted path must be unreadable without the key, a pre-existing
// plaintext database must migrate in place with its data intact, and a
// wrong key or corrupt file must fail closed. Backups made with VACUUM INTO
// from the encrypted live database must stay encrypted too.
//
// The key store here is an in-memory map behind
// SecureCredentialStore.debugStore, so no OS keychain is touched.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:front_porch_ai/database/database.dart';
import 'package:front_porch_ai/database/database.encryption.dart';
import 'package:front_porch_ai/services/storage/secure_credential_store.dart';

/// A validly-shaped but wrong 256-bit key (32 bytes of 0x07).
final _wrongKey = base64.encode(List<int>.filled(32, 7));

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
    _tmp = Directory.systemTemp.createTempSync('fpai_enc_test_');
  });

  tearDown(() async {
    SecureCredentialStore.debugStore = null;
    try {
      await _tmp.delete(recursive: true);
    } catch (_) {}
  });

  test('SQLCipher library is bundled (PRAGMA cipher_version)', () {
    final db = sqlite3.openInMemory();
    try {
      final rows = db.select('PRAGMA cipher_version;');
      expect(rows, isNotEmpty, reason: 'plain SQLite has no cipher_version');
    } finally {
      db.close();
    }
  });

  test('loadDatabaseKey generates once and returns the same key', () async {
    final first = await loadDatabaseKey();
    final second = await loadDatabaseKey();
    expect(first, second);
    expect(_keychain, contains(dbEncryptionKeyName));
    expect(base64.decode(first), hasLength(32));
  });

  test(
    'isPlaintextDatabase tells plaintext, encrypted, and empty apart',
    () async {
      final key = await loadDatabaseKey();
      final plain = _makePlaintextDb('plain.db');
      expect(isPlaintextDatabase(plain), isTrue);

      final empty = File('${_tmp.path}/empty.db')..createSync();
      expect(isPlaintextDatabase(empty), isFalse);

      await ensureDatabaseEncrypted(plain, key);
      expect(isPlaintextDatabase(plain), isFalse);
      expect(File('${plain.path}.encrypting').existsSync(), isFalse);
    },
  );

  test('fresh database created through the encrypted path is unreadable '
      'without the key', () async {
    final key = await loadDatabaseKey();
    final file = File('${_tmp.path}/fresh.db');
    final db = AppDatabase.forEncryptedFile(file, key);
    try {
      // First query runs Drift's schema creation through the encrypted
      // connection, so the file on disk holds real encrypted content.
      final rows = await db
          .customSelect('SELECT count(*) AS n FROM sqlite_master;')
          .get();
      expect(rows.single.read<int>('n'), greaterThan(0));
    } finally {
      await db.close();
    }

    expect(isPlaintextDatabase(file), isFalse);
    expect(_readWithoutKeyThrows(file), isTrue);
    expect(_readSchemaCountWithKey(file, key), greaterThan(0));
  });

  test(
    'pre-existing plaintext database migrates in place with data intact',
    () async {
      final key = await loadDatabaseKey();
      final file = _makePlaintextDb(
        'legacy.db',
        bodies: const ['alpha', 'beta', 'gamma'],
      );
      expect(isPlaintextDatabase(file), isTrue);

      await ensureDatabaseEncrypted(file, key);

      expect(isPlaintextDatabase(file), isFalse);
      expect(File('${file.path}.encrypting').existsSync(), isFalse);
      expect(_readWithoutKeyThrows(file), isTrue);
      expect(_readNotesWithKey(file, key), ['alpha', 'beta', 'gamma']);

      // The migrated file opens through Drift too, with the same rows.
      final db = AppDatabase.forEncryptedFile(file, key);
      try {
        final rows = await db
            .customSelect('SELECT body FROM notes ORDER BY id;')
            .get();
        expect(
          [for (final r in rows) r.read<String>('body')],
          ['alpha', 'beta', 'gamma'],
        );
      } finally {
        await db.close();
      }
    },
  );

  test('wrong key fails closed and leaves the file untouched', () async {
    final key = await loadDatabaseKey();
    final file = _makePlaintextDb('legacy.db', bodies: const ['alpha']);
    await ensureDatabaseEncrypted(file, key);
    final before = file.readAsBytesSync();

    await expectLater(
      ensureDatabaseEncrypted(file, _wrongKey),
      throwsA(isA<DatabaseEncryptionException>()),
    );
    expect(file.readAsBytesSync(), before);

    // The Drift open path fails closed too: the first query throws instead
    // of silently opening plaintext (there is no plaintext to open).
    final db = AppDatabase.forEncryptedFile(file, _wrongKey);
    try {
      await expectLater(db.customSelect('SELECT 1;').get(), throwsA(anything));
    } finally {
      await db.close();
    }
    expect(file.readAsBytesSync(), before);
  });

  test('corrupt file fails closed and is left untouched', () async {
    final key = await loadDatabaseKey();
    final file = File('${_tmp.path}/corrupt.db');
    final random = List<int>.generate(1024, (i) => (i * 37 + 11) % 256);
    file.writeAsBytesSync(random);
    final before = file.readAsBytesSync();

    await expectLater(
      ensureDatabaseEncrypted(file, key),
      throwsA(isA<DatabaseEncryptionException>()),
    );
    expect(file.readAsBytesSync(), before);
  });

  test(
    'VACUUM INTO from an encrypted database writes an encrypted backup',
    () async {
      final key = await loadDatabaseKey();
      final file = File('${_tmp.path}/live.db');
      final backup = File('${_tmp.path}/backup.db');
      final db = AppDatabase.forEncryptedFile(file, key);
      try {
        await db.customStatement(
          'CREATE TABLE backup_probe (id INTEGER PRIMARY KEY, body TEXT);',
        );
        await db.customStatement(
          "INSERT INTO backup_probe (body) VALUES ('keep-me');",
        );
        // Exactly the statement BackupService.createBackup runs.
        await db.customStatement(
          "VACUUM INTO '${backup.path.replaceAll("'", "''")}'",
        );
      } finally {
        await db.close();
      }

      expect(backup.existsSync(), isTrue);
      expect(isPlaintextDatabase(backup), isFalse);
      expect(_readWithoutKeyThrows(backup), isTrue);

      final raw = sqlite3.open(backup.path);
      try {
        setupEncryptedConnection(raw, key);
        final rows = raw.select('SELECT body FROM backup_probe;');
        expect([for (final r in rows) r['body']], ['keep-me']);
      } finally {
        raw.close();
      }
    },
  );
}

/// Builds a small plaintext database (no key) with a `notes` table.
File _makePlaintextDb(String name, {List<String> bodies = const []}) {
  final file = File('${_tmp.path}/$name');
  final db = sqlite3.open(file.path);
  try {
    db.execute(
      'CREATE TABLE notes (id INTEGER PRIMARY KEY, body TEXT NOT NULL);',
    );
    for (final body in bodies) {
      db.execute(
        "INSERT INTO notes (body) VALUES ('${body.replaceAll("'", "''")}');",
      );
    }
  } finally {
    db.close();
  }
  return file;
}

/// True when opening [file] without a key and reading fails.
bool _readWithoutKeyThrows(File file) {
  final db = sqlite3.open(file.path);
  try {
    db.select('SELECT count(*) FROM sqlite_master;');
    return false;
  } on SqliteException {
    return true;
  } finally {
    db.close();
  }
}

int _readSchemaCountWithKey(File file, String key) {
  final db = sqlite3.open(file.path);
  try {
    setupEncryptedConnection(db, key);
    return db.select('SELECT count(*) AS n FROM sqlite_master;').first['n']
        as int;
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
