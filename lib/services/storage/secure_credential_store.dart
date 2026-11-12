// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Read, write, and delete one string in the OS secure store.
typedef SecureStoreRead = Future<String?> Function(String key);
typedef SecureStoreWrite = Future<void> Function(String key, String value);
typedef SecureStoreDelete = Future<void> Function(String key);

/// The OS key store could not be read or written. Callers surface this
/// instead of silently falling back to plaintext storage — a silent fallback
/// would defeat the store.
class SecureCredentialStoreException implements Exception {
  const SecureCredentialStoreException(this.message);

  final String message;

  @override
  String toString() => 'SecureCredentialStoreException: $message';
}

/// One shared helper for every credential the app persists: remote API keys,
/// TTS keys, the web-search key, SuperGrok OAuth tokens, and the database
/// encryption key. All of them live only in the OS secure store
/// (Keychain / libsecret / Credential Manager) — never in
/// SharedPreferences, whose file is plaintext.
///
/// Migration is one-way: on load, a value still in prefs is moved into the
/// secure store and then deleted from prefs. A store read/write failure
/// throws [SecureCredentialStoreException]; callers must surface it, never
/// silently fall back to plaintext.
class SecureCredentialStore {
  final SecureStoreRead readKey;
  final SecureStoreWrite writeKey;
  final SecureStoreDelete deleteKey;

  SecureCredentialStore({
    required this.readKey,
    required this.writeKey,
    required this.deleteKey,
  });

  factory SecureCredentialStore.secure([
    FlutterSecureStorage storage = const FlutterSecureStorage(
      mOptions: MacOsOptions(usesDataProtectionKeychain: false),
    ),
  ]) {
    return SecureCredentialStore(
      readKey: (key) => storage.read(key: key),
      writeKey: (key, value) => storage.write(key: key, value: value),
      deleteKey: (key) => storage.delete(key: key),
    );
  }

  /// A test can hand in its own store, for example one that cannot be read.
  @visibleForTesting
  static SecureCredentialStore? debugStore;

  static Future<SecureCredentialStore> open() async {
    return debugStore ?? SecureCredentialStore.secure();
  }

  Future<T> _guard<T>(String action, Future<T> Function() run) async {
    try {
      return await run();
    } on ArgumentError {
      rethrow;
    } catch (e) {
      debugPrint('secure credential store $action failed: ${e.runtimeType}');
      throw SecureCredentialStoreException(
        action == 'read'
            ? 'Could not read the saved credential. Re-enter it to continue.'
            : 'Could not save the credential.',
      );
    }
  }

  /// Reads [key] from the secure store, or null when nothing is saved.
  /// Throws [SecureCredentialStoreException] when the store cannot be read.
  Future<String?> read(String key) {
    return _guard('read', () async {
      final value = await readKey(key);
      if (value == null || value.trim().isEmpty) return null;
      return value;
    });
  }

  /// Writes [value] to the secure store. An empty value throws
  /// [ArgumentError]; call [delete] to clear a credential instead.
  Future<void> write(String key, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) throw ArgumentError('value');
    return _guard('write', () => writeKey(key, trimmed));
  }

  /// Removes [key] from the secure store.
  Future<void> delete(String key) => _guard('write', () => deleteKey(key));

  /// Moves a credential still stored in [prefs] under [prefsKey] into the
  /// secure store under [secureKey], then deletes it from prefs. Returns
  /// the migrated value, or null when prefs held nothing. When the secure
  /// store already has a value, the prefs copy is deleted without
  /// overwriting it.
  Future<String?> migrateFromPrefs({
    required SharedPreferences? prefs,
    required String prefsKey,
    required String secureKey,
  }) async {
    final legacy = prefs?.getString(prefsKey)?.trim() ?? '';
    final existing = await read(secureKey);
    if (existing != null) {
      if (legacy.isNotEmpty) await prefs?.remove(prefsKey);
      return existing;
    }
    if (legacy.isEmpty) return null;
    await write(secureKey, legacy);
    await prefs?.remove(prefsKey);
    return legacy;
  }

  /// Reads [secureKey], migrating a leftover prefs value under [prefsKey]
  /// first when the secure store is empty. When the secure store already
  /// has a value it wins, and any leftover prefs copy is deleted without
  /// overwriting it. Returns null when neither holds a value.
  Future<String?> readOrMigrate({
    required SharedPreferences? prefs,
    required String prefsKey,
    required String secureKey,
  }) async {
    final existing = await read(secureKey);
    if (existing != null) {
      // Secure store wins, but the leftover plaintext prefs copy must
      // still be deleted — returning early here used to let it linger.
      await prefs?.remove(prefsKey);
      return existing;
    }
    return migrateFromPrefs(
      prefs: prefs,
      prefsKey: prefsKey,
      secureKey: secureKey,
    );
  }

  /// Reads the stored key under [secureKey], or generates a fresh random
  /// 256-bit key (base64), stores it, and returns it. The key is generated
  /// exactly once; a later call returns the same stored key.
  Future<String> getOrCreateKey(String secureKey) async {
    final existing = await read(secureKey);
    if (existing != null) return existing;
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final generated = base64.encode(bytes);
    await write(secureKey, generated);
    return generated;
  }
}
