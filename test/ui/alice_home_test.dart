// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Home ("On your porch") widget tests: the two states that matter
// are the Verse-3 first run (no characters, no worlds — empty states
// with create CTAs) and the populated porch (worlds as collapsible
// tier panels, characters as a grid with Edit + Delete). Navigation
// is exercised against a recording AppState double, so a CTA that
// goes nowhere fails here.
//
// Harness limits, honestly scoped: with characters present, the
// Continue-chatting future calls ChatService.getSessionsForId — an
// extension method that dispatches to the real database layer and so
// never completes against test doubles (and the loading skeleton
// pulses forever). Populated tests therefore pump a fixed number of
// frames instead of pumpAndSettle, assert the synchronous effects
// (rendering, navigation), and leave the session-load and delete
// pipelines to the service tests that cover them against a real
// repository (test/services/character_repository_test.dart,
// test/database/character_delete_cascade_test.dart).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/providers/app_state.dart';
import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/ui/alice/alice_home.dart';

import '../golden/support/fakes.dart';
import '../golden/support/fakes_storage.dart';

/// AppState double that records navigation instead of no-oping it.
class _RecordingAppState extends ChangeNotifier implements AppState {
  @override
  int selectedIndex = 0;

  int? lastIndex;

  @override
  void setIndex(int index) {
    lastIndex = index;
    selectedIndex = index;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Persona double: default persona only (name 'User' → plain greeting).
class _PersonaService extends ChangeNotifier implements UserPersonaService {
  @override
  UserPersona get defaultPersona => UserPersona(id: 'default');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Chat double (interface-level fake from the golden harness). The
/// chat-open and session-load calls Home makes are extension methods
/// that dispatch into the real ChatService pipeline, so they cannot
/// be intercepted here — see the header note.
class _HomeChatService extends FakeChatService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingAppState appState;
  late _HomeChatService chatService;

  Future<void> pumpFrames(WidgetTester tester, [int frames = 6]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> pumpHome(
    WidgetTester tester, {
    List<CharacterCard> characters = const [],
    List<World> worlds = const [],
    bool settle = true,
  }) async {
    appState = _RecordingAppState();
    chatService = _HomeChatService();
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StorageService>.value(
            value: FakeStorageService(),
          ),
          ChangeNotifierProvider<UserPersonaService>.value(
            value: _PersonaService(),
          ),
          ChangeNotifierProvider<CharacterRepository>.value(
            value: FakeCharacterRepository(characters),
          ),
          ChangeNotifierProvider<WorldRepository>.value(
            value: FakeWorldRepository(worlds),
          ),
          ChangeNotifierProvider<ChatService>.value(value: chatService),
          ChangeNotifierProvider<AppState>.value(value: appState),
        ],
        child: const MaterialApp(home: Scaffold(body: AliceHomeScreen())),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await pumpFrames(tester);
    }
  }

  group('Alice Home — first run (Verse 3 empty states)', () {
    testWidgets('no worlds and no characters shows both empty states', (
      tester,
    ) async {
      await pumpHome(tester);

      expect(find.text('On your porch'), findsOneWidget);
      expect(find.text('No worlds yet'), findsOneWidget);
      expect(find.text('Build your first world'), findsOneWidget);
      expect(find.text('No characters yet'), findsOneWidget);
      expect(find.text('Create your first character'), findsOneWidget);
      // Continue chatting is present and honestly empty.
      expect(find.textContaining('No stories yet'), findsOneWidget);
    });

    testWidgets('empty-state CTAs navigate to the real screens', (
      tester,
    ) async {
      await pumpHome(tester);

      await tester.tap(find.text('Build your first world'));
      await tester.pumpAndSettle();
      expect(appState.lastIndex, 3); // Worlds

      await tester.tap(find.text('Create your first character'));
      await tester.pumpAndSettle();
      expect(appState.lastIndex, 2); // Creator
    });
  });

  group('Alice Home — populated porch', () {
    final stage = World(
      id: 'w-stage',
      name: 'Aster Stage',
      lorebook: Lorebook(entries: []),
    )..tier = WorldTier.stage;
    final planet =
        World(
            id: 'w-planet',
            name: 'Pelion',
            description: 'A moss-coast world.',
            lorebook: Lorebook(entries: []),
          )
          ..tier = WorldTier.planet
          ..parentWorldId = 'w-stage';
    final mc = CharacterCard(
      name: 'Kael',
      personality: 'Dry-witted cartographer.',
      tags: const ['main-character'],
    );
    final npc = CharacterCard(
      name: 'Bram',
      description: 'Harbour mechanic.',
      frontPorchExtensions: FrontPorchExtensions(tier: 'lite'),
    );

    testWidgets('worlds render as labeled collapsible tier panels', (
      tester,
    ) async {
      await pumpHome(tester, worlds: [stage, planet]);

      // Root panel is labeled with tier + name.
      expect(find.text('Aster Stage'), findsOneWidget);
      expect(find.text('Stage'), findsOneWidget);

      // Drill down: expanding the Stage panel reveals the Planet child.
      await tester.tap(find.text('Aster Stage'));
      await tester.pumpAndSettle();
      expect(find.text('Pelion'), findsOneWidget);
      expect(find.text('Planet'), findsOneWidget);
    });

    testWidgets('characters render as a grid with roles, Edit and Delete', (
      tester,
    ) async {
      await pumpHome(tester, characters: [mc, npc], settle: false);

      expect(find.text('Kael'), findsOneWidget);
      expect(find.text('Bram'), findsOneWidget);
      expect(find.text('Main Character'), findsOneWidget);
      expect(find.text('NPC'), findsOneWidget);
      expect(find.text('Edit'), findsNWidgets(2));
      expect(find.text('Delete'), findsNWidgets(2));
      expect(find.text('New character'), findsOneWidget);
    });

    // Note: tapping a character card is not exercised here. The tap
    // calls ChatService.setActiveCharacter — the same extension-
    // dispatched real pipeline as getSessionsForId (save chain,
    // generation settle, DB session load) — which interface-level
    // doubles cannot stand in for. The handler itself is the
    // unchanged alice8 _openCharacter; the new wiring this screen
    // adds (CTAs, panels, grid, Edit/Delete) is what these tests pin.

    testWidgets('Delete asks for confirmation; Cancel keeps the card', (
      tester,
    ) async {
      await pumpHome(tester, characters: [mc, npc], settle: false);

      await tester.tap(find.text('Delete').first);
      await pumpFrames(tester);

      expect(find.text('Delete Kael?'), findsOneWidget);
      expect(find.textContaining('can’t be undone'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancel'),
        ),
      );
      await pumpFrames(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Kael'), findsOneWidget);
      expect(find.text('Bram'), findsOneWidget);
    });
  });
}
