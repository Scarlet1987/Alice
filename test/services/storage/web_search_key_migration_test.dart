// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Tavily lives ONLY in the OS secure store (Finding 1, audit §4a). A key
// still in SharedPreferences is moved into the secure store on load and
// the prefs copy is deleted; when the secure store already has a value it
// wins and the prefs copy is deleted without overwriting it. Nothing is
// ever written back to prefs.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_porch_ai/app_version.dart';
import 'package:front_porch_ai/services/storage/storage.dart';

String get _key => isPreRelease ? 'beta_search_api_key' : 'search_api_key';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a prefs value migrates into the secure store and is deleted from prefs on load',
    () async {
      SharedPreferences.setMockInitialValues({_key: '  tavily-legacy  '});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = WebSearchSettings()..initializeBase(prefs, () {});

      await settings.load();

      expect(settings.searchApiKey, 'tavily-legacy');
      expect(settings.hasApiKey, isTrue);
      expect(prefs.containsKey(_key), isFalse);
      expect(
        await const FlutterSecureStorage().read(key: _key),
        'tavily-legacy',
      );
    },
  );

  test('secure store wins when both stores have a value', () async {
    SharedPreferences.setMockInitialValues({_key: 'from-prefs'});
    FlutterSecureStorage.setMockInitialValues({_key: 'from-keychain'});
    final prefs = await SharedPreferences.getInstance();
    final settings = WebSearchSettings()..initializeBase(prefs, () {});

    await settings.load();

    expect(settings.searchApiKey, 'from-keychain');
    expect(prefs.containsKey(_key), isFalse);
    expect(await const FlutterSecureStorage().read(key: _key), 'from-keychain');
  });

  test(
    'saving writes the secure store only; clearing removes it from the secure store',
    () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = WebSearchSettings()..initializeBase(prefs, () {});
      await settings.load();

      await settings.setSearchApiKey('tavily-new');
      expect(settings.hasApiKey, isTrue);
      expect(prefs.containsKey(_key), isFalse);
      expect(await const FlutterSecureStorage().read(key: _key), 'tavily-new');

      await settings.setSearchApiKey('');
      expect(settings.hasApiKey, isFalse);
      expect(prefs.containsKey(_key), isFalse);
      expect(await const FlutterSecureStorage().read(key: _key), isNull);
    },
  );
}
