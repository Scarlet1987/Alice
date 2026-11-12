// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

// Finding 1 (audit §4a): credentials live ONLY in the OS secure store.
// No credential value is written to SharedPreferences anywhere in lib/.
// Each test below uses an in-memory fake secure store (never a real
// keychain) and asserts on the store contents and on the prefs file —
// the values themselves are test fixtures, never real credentials.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_porch_ai/services/storage/secure_credential_store.dart';
import 'package:front_porch_ai/services/storage/settings/backend_settings.dart';
import 'package:front_porch_ai/services/storage/settings/remote_api_key_vault.dart';
import 'package:front_porch_ai/services/storage/settings/tts_settings.dart';
import 'package:front_porch_ai/services/storage/settings/web_search_settings.dart';
import 'package:front_porch_ai/services/xai/super_grok_auth.dart';
import 'package:front_porch_ai/services/xai/xai_tokens.dart';

/// In-memory stand-in for the OS secure store, with an optional failure
/// switch to prove the fail-closed behaviour.
class _FakeSecureStore {
  final Map<String, String> values = {};
  bool failReads = false;
  bool failWrites = false;

  SecureCredentialStore get store => SecureCredentialStore(
    readKey: (key) async {
      if (failReads) throw StateError('store unreadable');
      return values[key];
    },
    writeKey: (key, value) async {
      if (failWrites) throw StateError('store unwritable');
      values[key] = value;
    },
    deleteKey: (key) async {
      if (failWrites) throw StateError('store unwritable');
      values.remove(key);
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureCredentialStore', () {
    test('round-trips a value and deletes it', () async {
      final fake = _FakeSecureStore();
      await fake.store.write('k', 'v');
      expect(await fake.store.read('k'), 'v');
      await fake.store.delete('k');
      expect(await fake.store.read('k'), isNull);
    });

    test('a read failure throws instead of returning a fallback', () async {
      final fake = _FakeSecureStore()..failReads = true;
      expect(
        () => fake.store.read('k'),
        throwsA(isA<SecureCredentialStoreException>()),
      );
    });

    test('a write failure throws instead of falling back to prefs', () async {
      final fake = _FakeSecureStore()..failWrites = true;
      expect(
        () => fake.store.write('k', 'v'),
        throwsA(isA<SecureCredentialStoreException>()),
      );
    });

    test(
      'migrateFromPrefs moves the value and deletes the prefs copy',
      () async {
        SharedPreferences.setMockInitialValues({'legacy_key': 'keep-me'});
        final prefs = await SharedPreferences.getInstance();
        final fake = _FakeSecureStore();
        final moved = await fake.store.migrateFromPrefs(
          prefs: prefs,
          prefsKey: 'legacy_key',
          secureKey: 'secure_key',
        );
        expect(moved, 'keep-me');
        expect(fake.values['secure_key'], 'keep-me');
        expect(prefs.containsKey('legacy_key'), isFalse);
      },
    );

    test('getOrCreateKey generates once and returns the same key', () async {
      final fake = _FakeSecureStore();
      final first = await fake.store.getOrCreateKey('db_key');
      final second = await fake.store.getOrCreateKey('db_key');
      expect(first, second);
      // 32 random bytes, base64-encoded.
      expect(base64.decode(first), hasLength(32));
    });
  });

  group('BackendSettings secrets', () {
    test(
      'legacy prefs keys migrate to the secure store on loadSecrets',
      () async {
        SharedPreferences.setMockInitialValues({
          'remote_api_url': 'https://openrouter.ai/api/v1',
          'remote_api_key': 'sk-or-legacy',
          'remote_api_keys': jsonEncode({
            'https://nano-gpt.com/api/v1': 'sk-nano-legacy',
          }),
        });
        final prefs = await SharedPreferences.getInstance();
        final fake = _FakeSecureStore();
        final settings = BackendSettings(secureStore: fake.store)
          ..initializeBase(prefs, () {});
        settings.load();
        expect(
          settings.remoteApiKey,
          isEmpty,
          reason: 'keys are not readable before loadSecrets',
        );
        await settings.loadSecrets();

        expect(settings.remoteApiKey, 'sk-or-legacy');
        expect(
          settings.remoteApiKeyFor('https://nano-gpt.com/api/v1'),
          'sk-nano-legacy',
        );
        expect(prefs.containsKey('remote_api_key'), isFalse);
        expect(prefs.containsKey('remote_api_keys'), isFalse);
        expect(fake.values['remote_api_keys'], isNotNull);
      },
    );

    test('setRemoteApiKey writes the secure store, never prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeSecureStore();
      final settings = BackendSettings(secureStore: fake.store)
        ..initializeBase(prefs, () {});
      settings.load();
      await settings.setRemoteApiKey('sk-or-new');

      expect(settings.remoteApiKey, 'sk-or-new');
      expect(prefs.containsKey('remote_api_key'), isFalse);
      expect(prefs.containsKey('remote_api_keys'), isFalse);
      expect(
        RemoteApiKeyVault.decode(
          fake.values['remote_api_keys'],
        ).keyFor('https://openrouter.ai/api/v1'),
        'sk-or-new',
      );
    });

    test('a failing secure store leaves the in-memory key unchanged', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeSecureStore()..failWrites = true;
      final settings = BackendSettings(secureStore: fake.store)
        ..initializeBase(prefs, () {});
      settings.load();
      await expectLater(
        settings.setRemoteApiKey('sk-or-new'),
        throwsA(isA<SecureCredentialStoreException>()),
      );
      expect(settings.remoteApiKey, isEmpty);
      expect(prefs.containsKey('remote_api_key'), isFalse);
    });
  });

  group('TtsSettings secrets', () {
    test('legacy prefs keys migrate to the secure store', () async {
      SharedPreferences.setMockInitialValues({
        'openai_tts_api_key': 'tts-openai-legacy',
        'elevenlabs_api_key': 'tts-eleven-legacy',
      });
      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeSecureStore();
      final settings = TtsSettings(secureStore: fake.store)
        ..initializeBase(prefs, () {});
      settings.load();
      await settings.loadSecrets();

      expect(settings.openaiTtsApiKey, 'tts-openai-legacy');
      expect(settings.elevenlabsApiKey, 'tts-eleven-legacy');
      expect(prefs.containsKey('openai_tts_api_key'), isFalse);
      expect(prefs.containsKey('elevenlabs_api_key'), isFalse);
      expect(fake.values['openai_tts_api_key'], 'tts-openai-legacy');
      expect(fake.values['elevenlabs_api_key'], 'tts-eleven-legacy');
    });

    test('setters write the secure store, never prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeSecureStore();
      final settings = TtsSettings(secureStore: fake.store)
        ..initializeBase(prefs, () {});
      settings.load();
      await settings.setOpenaiTtsApiKey('tts-openai-new');
      await settings.setElevenlabsApiKey('tts-eleven-new');

      expect(prefs.containsKey('openai_tts_api_key'), isFalse);
      expect(prefs.containsKey('elevenlabs_api_key'), isFalse);
      expect(fake.values['openai_tts_api_key'], 'tts-openai-new');
      expect(fake.values['elevenlabs_api_key'], 'tts-eleven-new');

      await settings.setOpenaiTtsApiKey('');
      expect(fake.values.containsKey('openai_tts_api_key'), isFalse);
      expect(settings.openaiTtsApiKey, isEmpty);
    });
  });

  group('WebSearchSettings secret', () {
    test('legacy prefs key migrates to the secure store on load', () async {
      SharedPreferences.setMockInitialValues({
        'search_api_key': 'tavily-legacy',
      });
      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeSecureStore();
      final settings = WebSearchSettings(secureStore: fake.store)
        ..initializeBase(prefs, () {});
      await settings.load();

      expect(settings.searchApiKey, 'tavily-legacy');
      expect(prefs.containsKey('search_api_key'), isFalse);
      expect(fake.values['search_api_key'], 'tavily-legacy');
    });

    test('setSearchApiKey writes the secure store, never prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeSecureStore();
      final settings = WebSearchSettings(secureStore: fake.store)
        ..initializeBase(prefs, () {});
      await settings.load();
      await settings.setSearchApiKey('tavily-new');

      expect(settings.searchApiKey, 'tavily-new');
      expect(prefs.containsKey('search_api_key'), isFalse);
      expect(fake.values['search_api_key'], 'tavily-new');
    });
  });

  group('SuperGrokAuth secure session', () {
    test('a prefs session migrates to the secure store on load', () async {
      final tokens = XaiTokens(
        accessToken: 'session-access',
        refreshToken: 'session-refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        email: 'porch@example.com',
      );
      SharedPreferences.setMockInitialValues({
        'xai_supergrok_session': tokens.encode(),
      });
      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeSecureStore();
      final auth = SuperGrokAuth.inSecureStore(
        () => prefs,
        'xai_supergrok_session',
        store: fake.store,
      );
      addTearDown(auth.dispose);
      await auth.load();

      expect(auth.phase, SuperGrokPhase.signedIn);
      expect(auth.email, 'porch@example.com');
      expect(auth.bearerFor('https://api.x.ai/v1'), 'session-access');
      expect(prefs.containsKey('xai_supergrok_session'), isFalse);
      expect(fake.values['xai_supergrok_session'], tokens.encode());

      await auth.signOut();
      expect(auth.isSignedIn, isFalse);
      expect(fake.values.containsKey('xai_supergrok_session'), isFalse);
    });
  });
}
