// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice FAQ guard: the "FAQ definitions" Jump To entry opens the real
// FAQ screen (Elaina, 2026-11-14 — the FAQ feature, built from the
// approved preview), with the policy questions, the draft guide, the
// suggestion box, and the running file. Back returns to Home. A
// submitted request lands in the feedback file on disk.
// UNRUN in the VM that wrote it (no Flutter/Dart there) — run on metal:
//   flutter test test/ui/alice/v9/alice_v9_faq_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import 'package:front_porch_ai/database/database.dart';
import 'package:front_porch_ai/providers/app_state.dart';
import 'package:front_porch_ai/services/character_repository.dart';
import 'package:front_porch_ai/services/feedback_file_service.dart';
import 'package:front_porch_ai/services/storage_service.dart';
import 'package:front_porch_ai/services/world_repository.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_shell.dart';
import 'package:front_porch_ai/utils/picker_prefs.dart';

import '../../../golden/support/creator_test_support.dart';

/// Pumps the v9 shell and returns the storage, so the test can read
/// the feedback file the screen wrote.
Future<StorageService> _pumpShell(WidgetTester tester, Size size) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupPathProviderMock();
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
    // from Home is a sibling of the home route, not its descendant.
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StorageService>.value(value: storage),
        ChangeNotifierProvider<CharacterRepository>.value(value: characters),
        ChangeNotifierProvider<WorldRepository>.value(value: worlds),
        ChangeNotifierProvider<AppState>(create: (_) => AppState()),
      ],
      child: const MaterialApp(home: AliceV9Shell()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return storage;
}


/// Settles with real async enabled, so the screen's file I/O (load on
/// open, save on submit) actually completes — plain pumpAndSettle
/// leaves real-async work pending in the fake-async zone.
Future<void> _settle(WidgetTester tester) =>
    tester.runAsync(tester.pumpAndSettle);

Future<void> _openFaq(WidgetTester tester) async {
  // The Jump rail sits below the fold at 1280x720 (the hero is tall),
  // so scroll it into view before tapping — a tap on an off-screen
  // offset throws instead of scrolling.
  await tester.ensureVisible(find.text('faq definitions'));
  await tester.tap(find.text('faq definitions'));
  await _settle(tester);
  expect(find.text('Questions, complaints & requests'), findsOneWidget);
}

Finder _fieldByHint(String hint) => find.byWidgetPredicate(
  (widget) =>
      widget is TextField && widget.decoration?.hintText == hint,
);

void main() {
  testWidgets('FAQ opens from Jump To and Back returns to Home', (
    tester,
  ) async {
    await _pumpShell(tester, const Size(1280, 720));
    await _openFaq(tester);
    expect(find.text('Is Alice free?'), findsOneWidget);
    expect(find.text('New here? Start with these'), findsOneWidget);
    expect(find.text('The suggestion box'), findsOneWidget);
    expect(find.text('The running file'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await _settle(tester);
    expect(find.text('Questions, complaints & requests'), findsNothing);
    expect(find.text('Alice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('submitting a request adds it to the file on disk', (
    tester,
  ) async {
    final storage = await _pumpShell(tester, const Size(1280, 720));
    await _openFaq(tester);
    await tester.ensureVisible(
      _fieldByHint('e.g. Replies stop mid-sentence on long chats'),
    );
    await tester.enterText(
      _fieldByHint('e.g. Replies stop mid-sentence on long chats'),
      'Replies stop mid-sentence on long chats',
    );
    await tester.ensureVisible(find.text('Add it to the file'));
    await tester.tap(find.text('Add it to the file'));
    await _settle(tester);
    expect(
      find.text('Added — it\'s in the file below, under its category.'),
      findsOneWidget,
    );
    expect(find.text('Chat & replies — 1 entry'), findsOneWidget);
    expect(
      find.text('1. [Request] Replies stop mid-sentence on long chats'),
      findsOneWidget,
    );
    final file = File(
      path.join(storage.feedbackDir.path, FeedbackFile.fileName),
    );
    expect(file.existsSync(), isTrue);
    expect(
      file.readAsStringSync(),
      contains('Replies stop mid-sentence on long chats'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty What shows the error and saves nothing', (
    tester,
  ) async {
    final storage = await _pumpShell(tester, const Size(1280, 720));
    await _openFaq(tester);
    await tester.ensureVisible(find.text('Add it to the file'));
    await tester.tap(find.text('Add it to the file'));
    await _settle(tester);
    expect(
      find.text(
        'The file needs the What — everything else can be filled in as '
        'best you can.',
      ),
      findsOneWidget,
    );
    final file = File(
      path.join(storage.feedbackDir.path, FeedbackFile.fileName),
    );
    expect(file.existsSync(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('out-of-beta mark reveals the done-list', (tester) async {
    await _pumpShell(tester, const Size(1280, 720));
    await _openFaq(tester);
    expect(
      find.text('Everything Alice ships with works — every feature in the '
          'box does what it says.'),
      findsNothing,
    );
    await tester.ensureVisible(find.text('Out of beta — the v2.0 jump'));
    await tester.tap(find.text('Out of beta — the v2.0 jump'));
    await _settle(tester);
    expect(find.text('The out-of-beta test'), findsOneWidget);
    expect(
      find.text('Everything Alice ships with works — every feature in the '
          'box does what it says.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Download hands the markdown to the save picker', (
    tester,
  ) async {
    await _pumpShell(tester, const Size(1280, 720));
    await _openFaq(tester);
    Uint8List? captured;
    PickerPrefs.testSaveFileOverride =
        ({required category, required bytes, dialogTitle, fileName, type,
          allowedExtensions}) async {
          captured = bytes;
          return '/tmp/alice-feedback-file.md';
        };
    addTearDown(() => PickerPrefs.testSaveFileOverride = null);
    await tester.ensureVisible(find.text('Download the file'));
    await tester.tap(find.text('Download the file'));
    await _settle(tester);
    expect(captured, isNotNull);
    expect(
      utf8.decode(captured!),
      contains('# Alice — Feedback File'),
    );
    expect(tester.takeException(), isNull);
  });
}
