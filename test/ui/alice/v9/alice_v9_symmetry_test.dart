// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 symmetry guard: Elaina's metal screenshots (2026-11-13) showed
// the Home page looking un-crisp — same-height Stage / Current Char cards
// whose insides did not line up (Char's extra paragraph pushed its Cover
// Flow and its +new/edit/-del row ~50px below Stage's), a Jump rail of
// ragged pills ("faq definitions" wrapped to two lines), and a hero whose
// pitch floated ~100px below the buy-once card's top because the hero Row
// centred its children instead of top-aligning them.
// Rule (Elaina, 2026-11-13): non-organic UI is symmetrical — straight
// edges where things must line up; asymmetry is only for things that can
// afford it, balanced by weight, never by sloppy edges.
// UNRUN in the VM that wrote it (no Flutter/Dart there) — run on metal:
//   flutter test test/ui/alice/v9/alice_v9_symmetry_test.dart

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
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<StorageService>.value(value: storage),
          ChangeNotifierProvider<CharacterRepository>.value(value: characters),
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
  testWidgets('Stage and Current Char button rows share one line', (
    tester,
  ) async {
    await _pumpShell(tester, const Size(1735, 1150));
    // '-del' appears once per card's button row and nowhere else.
    expect(find.text('-del'), findsNWidgets(2));
    final tops = [
      tester.getTopLeft(find.text('-del').first).dy,
      tester.getTopLeft(find.text('-del').last).dy,
    ];
    expect(tops[0], moreOrLessEquals(tops[1], epsilon: 1.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Jump rail buttons are one straight stack', (tester) async {
    await _pumpShell(tester, const Size(1735, 1150));
    const labels = [
      'world lore',
      'equip',
      'char card',
      'faq definitions',
      'benchmark',
      'start server',
    ];
    final sizes = <Size>[];
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byType(ElevatedButton),
      );
      sizes.add(tester.getSize(button));
    }
    for (final size in sizes) {
      expect(size.height, moreOrLessEquals(sizes.first.height, epsilon: 1.0));
      expect(size.width, moreOrLessEquals(sizes.first.width, epsilon: 1.0));
    }
    // A wrapping label would overflow its fixed-height box.
    expect(tester.takeException(), isNull);
  });

  testWidgets('hero pitch and buy-once card start on the same line', (
    tester,
  ) async {
    await _pumpShell(tester, const Size(1735, 1150));
    expect(find.text('Alice'), findsOneWidget);
    // Nearest Container ancestor is the buy-once card itself; further up
    // the tree the hero section has its own Container.
    final card = find
        .ancestor(
          of: find.text('A program you own'),
          matching: find.byType(Container),
        )
        .first;
    expect(
      tester.getTopLeft(find.text('Alice')).dy,
      moreOrLessEquals(tester.getTopLeft(card).dy, epsilon: 1.0),
    );
    expect(tester.takeException(), isNull);
  });
}
