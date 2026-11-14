// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Worlds back-button guard: Elaina (2026-11-14) asked whether
// clicking +new stage lets her go back even if she built nothing and
// saved nothing. Opening the Worlds screen creates and saves nothing
// (a world is only saved when the new-world dialog is confirmed), but
// the screen had NO way back at all — no back button, no AppBar, and
// no system back on desktop — so the only way out was closing the app.
// The Worlds header now carries a Back button that pops the route.
// UNRUN in the VM that wrote it (no Flutter/Dart there) — run on metal:
//   flutter test test/ui/alice/alice_worlds_back_button_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/database/database.dart';
import 'package:front_porch_ai/providers/app_state.dart';
import 'package:front_porch_ai/services/character_repository.dart';
import 'package:front_porch_ai/services/storage_service.dart';
import 'package:front_porch_ai/services/world_repository.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_shell.dart';

import '../../golden/support/creator_test_support.dart';

/// Pumps the v9 shell and returns the world repository, so the test
/// can prove the round trip saved nothing.
Future<WorldRepository> _pumpShell(WidgetTester tester, Size size) async {
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
    // Providers sit ABOVE MaterialApp, like the real app: a route pushed
    // from Home is a sibling of the home route, not its descendant, so
    // providers wrapped around `home` alone are invisible to it — the
    // Worlds screen would throw ProviderNotFound for WorldRepository.
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StorageService>.value(value: storage),
        ChangeNotifierProvider<CharacterRepository>.value(value: characters),
        ChangeNotifierProvider<WorldRepository>.value(value: worlds),
        // The Worlds screen reads AppState (a lore link switches the
        // outer tab), so it must exist above the shell.
        ChangeNotifierProvider<AppState>(create: (_) => AppState()),
      ],
      child: const MaterialApp(home: AliceV9Shell()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return worlds;
}

Future<void> _openWorlds(WidgetTester tester) async {
  // Stage's +new is the first +new in the tree (Stage card, then Char).
  await tester.tap(find.text('+new').first);
  await tester.pumpAndSettle();
  expect(find.text('Worlds'), findsOneWidget);
}

void main() {
  testWidgets('Back returns to Home from the Worlds screen', (tester) async {
    await _pumpShell(tester, const Size(1280, 720));
    await _openWorlds(tester);
    expect(find.text('Back'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Worlds'), findsNothing);
    expect(find.text('Alice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening Worlds and going back saves nothing', (tester) async {
    final worlds = await _pumpShell(tester, const Size(1280, 720));
    expect(worlds.placeWorlds, isEmpty);
    await _openWorlds(tester);
    expect(find.text('Back'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsOneWidget);
    expect(worlds.placeWorlds, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
