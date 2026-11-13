// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 shell overflow guard: Elaina's metal run (2026-11-13) hit
// "RenderFlex overflowed by 240 pixels on the bottom" in
// alice_v9_shell.dart at a 1691x393 window — the full hero is taller
// than a short window, so the fixed Column overflowed and the content
// below the hero was unreachable. In a short window the hero compacts
// and scrolls inside its own space instead of overflowing.
// UNRUN in the VM that wrote it (no Flutter/Dart there) — run on metal:
//   flutter test test/ui/alice/v9/alice_v9_shell_overflow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/database/database.dart';
import 'package:front_porch_ai/services/character_repository.dart';
import 'package:front_porch_ai/services/storage_service.dart';
import 'package:front_porch_ai/services/world_repository.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_shell.dart';

import '../../../golden/support/creator_test_support.dart';

Future<void> _pumpShell(WidgetTester tester, Size size) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupPathProviderMock();
  // Real async work (StorageService init does real directory creates,
  // the repositories start real DB loads) must run outside the
  // testWidgets fake-async zone, or the first await never completes
  // and the test hangs at 0% CPU.
  late final StorageService storage;
  late final AppDatabase db;
  late final CharacterRepository characters;
  late final WorldRepository worlds;
  await tester.runAsync(() async {
    storage = await makeGoldenStorage();
    db = AppDatabase.forTesting(sameIsolate: true);
    characters = CharacterRepository(db, storage);
    worlds = WorldRepository(storage, db);
    worlds.setCharacterRepository(characters);
  });
  addTearDown(() async => db.close());
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<StorageService>.value(value: storage),
          ChangeNotifierProvider<CharacterRepository>.value(
            value: characters,
          ),
          ChangeNotifierProvider<WorldRepository>.value(value: worlds),
        ],
        child: const AliceV9Shell(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('no overflow at the 1691x393 metal window size', (tester) async {
    await _pumpShell(tester, const Size(1691, 393));
    expect(find.text('Alice'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow at a normal 1280x720 window', (tester) async {
    await _pumpShell(tester, const Size(1280, 720));
    expect(find.text('Alice'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
