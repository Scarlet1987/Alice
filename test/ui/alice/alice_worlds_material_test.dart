// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Worlds page Material guard: Elaina's metal run (2026-11-13) showed the
// Worlds page replaced by Flutter's red error screen — "No Material widget
// found" — thrown by three InkWells with no Material ancestor above them
// (the Lore Book link in alice_worlds.dart, the tier-section header and
// the world row in alice_worlds_sections.dart). The page sits under
// AliceTranslucentCard (ClipRRect > BackdropFilter > Container), so there
// is no Material / Scaffold / Card anywhere above those InkWells.
// The fix wraps each InkWell in a transparent Material, which is
// invisible and keeps the frosted-card look.
// UNRUN in the VM that wrote it (no Flutter/Dart there) — run on metal:
//   flutter test test/ui/alice/alice_worlds_material_test.dart
// NOTE: with no worlds saved, opening a section shows the "No universe
// yet" text and no world row, so this test exercises the header and
// Lore Book InkWells; the row InkWell gets the same wrap and is verified
// by inspection (no InkWell in the Worlds files may sit outside a
// transparent Material).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/database/database.dart';
import 'package:front_porch_ai/providers/app_state.dart';
import 'package:front_porch_ai/services/character_repository.dart';
import 'package:front_porch_ai/services/storage_service.dart';
import 'package:front_porch_ai/services/world_repository.dart';
import 'package:front_porch_ai/ui/alice/alice_worlds.dart';

import '../../golden/support/creator_test_support.dart';

void main() {
  testWidgets('Worlds page builds with no Material errors', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupPathProviderMock();
    // Real async work must run outside the testWidgets fake-async zone, or
    // the first await never completes and the test hangs at 0% CPU.
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
    tester.view.physicalSize = const Size(1280, 720);
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
            ChangeNotifierProvider<AppState>(create: (_) => AppState()),
          ],
          child: const AliceWorldsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Worlds'), findsOneWidget);
    // Open the first tier section, so its header InkWell is exercised
    // while open as well as closed. "Universe" matches twice — the Jump
    // to pill and the tier header — so take the last, the header.
    await tester.tap(find.text('Universe').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The page must sit under a Material: without one, headings that use
    // plain const TextStyles inherit Flutter's fallback style — red,
    // monospace, underlined — instead of the theme. (Found 2026-11-13
    // from Elaina's screenshots: "Worlds", "Stage" and the rule titles
    // rendered red serif underlined while tier titles rendered normally,
    // because only the tier sections sat under the wrapped InkWells.)
    final worldsAmbient = DefaultTextStyle.of(
      tester.element(find.text('Worlds')),
    ).style;
    expect(worldsAmbient.decoration, TextDecoration.none);
    expect(worldsAmbient.fontFamily, isNot('monospace'));
  });
}
