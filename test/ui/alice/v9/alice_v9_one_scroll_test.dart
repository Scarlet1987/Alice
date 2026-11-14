// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 one-scroll guard: Elaina (2026-11-14) — the face does not
// change, the action does. The whole shell is ONE scroll area: hero,
// nav, page, mint bar all move together like one HTML document. Before
// this, the shell pinned hero/nav/mint bar and each page had its own
// scroll view, so the wheel fought between regions and the hero stayed
// put while the page moved (the "hiccups" on metal).
// The rule: exactly one SingleChildScrollView in the shell subtree.
// The measurements GridView is shrinkWrap + NeverScrollable, so it is
// layout, not a scroll area, and does not count.
// UNRUN in the VM that wrote it (no Flutter/Dart there) — run on metal:
//   flutter test test/ui/alice/v9/alice_v9_one_scroll_test.dart

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
  testWidgets('one scroll area at a tall 1280x720 window', (tester) async {
    await _pumpShell(tester, const Size(1280, 720));
    // skipOffstage false: the old shell kept all four pages in an
    // IndexedStack, so the hidden pages' scroll views are offstage but
    // still in the tree — the default finder skips them and would pass
    // the old code at tall windows.
    expect(
      find.byType(SingleChildScrollView, skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('one scroll area at the short 1691x393 metal window', (
    tester,
  ) async {
    await _pumpShell(tester, const Size(1691, 393));
    expect(
      find.byType(SingleChildScrollView, skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dragging scrolls the hero away as one document', (
    tester,
  ) async {
    await _pumpShell(tester, const Size(1280, 720));
    expect(find.text('Alice'), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pump();
    // The hero scrolled off the top with the rest of the document.
    // hitTestable, not findsNothing: scrolled-off content is still in
    // the widget tree, just outside the viewport and un-hittable.
    expect(find.text('Alice').hitTestable(), findsNothing);
    // And the foot of the document — the mint bar — scrolled into view.
    expect(
      find
          .text('One-time purchase. No subscription, no rent, no cloud.')
          .hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
