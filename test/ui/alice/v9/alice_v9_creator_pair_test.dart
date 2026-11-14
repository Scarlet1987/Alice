// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 Creator-pair guard: Elaina's continuity check (2026-11-14) —
// the same look shot to shot, no jump cuts. Two breaks on the Creator
// page: (1) the picked gender/pronoun pill inverted to WHITE with green
// words, while everywhere else picked means solid green with white
// words (Home nav, playground 7B) — the same state looked different
// from shot to shot; (2) the MC and NPC cards did not share a height —
// MC ended early, NPC ran long, bottom edges ragged — where Home's
// Stage / Current Char pair shares one skeleton with its button rows
// on one line. The fix: picked pills are solid green, and the pair
// shares one height with both Save buttons on one line.
// UNRUN in the VM that wrote it (no Flutter/Dart there) — run on metal:
//   flutter test test/ui/alice/v9/alice_v9_creator_pair_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/database/database.dart';
import 'package:front_porch_ai/services/character_repository.dart';
import 'package:front_porch_ai/services/storage_service.dart';
import 'package:front_porch_ai/services/world_repository.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_shell.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

import '../../../golden/support/creator_test_support.dart';

Future<void> _pumpCreator(WidgetTester tester) async {
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
        ],
        child: const AliceV9Shell(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text('Char creator'));
  await tester.pumpAndSettle();
  expect(find.text('name and gender (MC)'), findsOneWidget);
  expect(find.text('name and gender (NPC)'), findsOneWidget);
}

Size _cardSize(WidgetTester tester, String heading) {
  // Nearest V9Card ancestor is the card itself.
  final card = find
      .ancestor(of: find.text(heading), matching: find.byType(V9Card))
      .first;
  return tester.getSize(card);
}

void main() {
  testWidgets('MC and NPC cards share one height', (tester) async {
    await _pumpCreator(tester);
    final mc = _cardSize(tester, 'name and gender (MC)');
    final npc = _cardSize(tester, 'name and gender (NPC)');
    expect(mc.height, moreOrLessEquals(npc.height, epsilon: 1.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('both Save buttons sit on one line', (tester) async {
    await _pumpCreator(tester);
    final mcTop = tester.getTopLeft(find.text('Save main character')).dy;
    final npcTop = tester.getTopLeft(find.text('Save NPC')).dy;
    expect(mcTop, moreOrLessEquals(npcTop, epsilon: 1.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the picked pill is solid green, like every other pick', (
    tester,
  ) async {
    await _pumpCreator(tester);
    // 'male' is the default pick in both cards; the first is MC's.
    // Nearest Container ancestor is the option button itself.
    final button = find
        .ancestor(of: find.text('male').first, matching: find.byType(Container))
        .first;
    final decoration =
        tester.widget<Container>(button).decoration as BoxDecoration;
    expect(decoration.color, AppColors.aliceGreen);
    expect(
      tester.widget<Text>(find.text('male').first).style?.color,
      AppColors.pureWhite,
    );
    expect(tester.takeException(), isNull);
  });
}
