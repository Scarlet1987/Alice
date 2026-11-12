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

// Tavily lives ONLY in the OS secure store (Finding 1, audit §4a), so the
// secure store is the durable copy across restarts — SharedPreferences
// never holds the key and cannot resurrect it. An emptied secure store
// loses the key (fail closed); nothing falls back to plaintext.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_porch_ai/app_version.dart';
import 'package:front_porch_ai/services/storage/storage.dart';

String get _key => isPreRelease ? 'beta_search_api_key' : 'search_api_key';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Tavily key survives a restart from the secure store; an emptied keychain loses it',
    () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final first = WebSearchSettings()..initializeBase(prefs, () {});
      await first.load();
      await first.setSearchApiKey('tavily-keep-me');

      // Restart with the secure store intact: the key comes back, and
      // prefs never holds a copy of it.
      final second = WebSearchSettings()..initializeBase(prefs, () {});
      await second.load();

      expect(second.searchApiKey, 'tavily-keep-me');
      expect(prefs.containsKey(_key), isFalse);

      // Restart with the secure store emptied: the key is gone and prefs
      // does not resurrect it — fail closed, no plaintext fallback.
      FlutterSecureStorage.setMockInitialValues({});
      final third = WebSearchSettings()..initializeBase(prefs, () {});
      await third.load();

      expect(third.searchApiKey, isEmpty);
      expect(third.hasApiKey, isFalse);
      expect(prefs.containsKey(_key), isFalse);
    },
  );

  test(
    'a keychain-only value loads from the secure store and is not copied into prefs',
    () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({_key: 'from-keychain'});
      final prefs = await SharedPreferences.getInstance();
      final settings = WebSearchSettings()..initializeBase(prefs, () {});
      await settings.load();

      expect(settings.searchApiKey, 'from-keychain');
      expect(prefs.containsKey(_key), isFalse);
      expect(
        await const FlutterSecureStorage().read(key: _key),
        'from-keychain',
      );
    },
  );
}
