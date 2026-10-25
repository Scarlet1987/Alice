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

// The plain-English glossary: term chips open their definition, and the full
// dialog lists every term.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:front_porch_ai/ui/widgets/glossary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GlossaryChip opens the term definition on tap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GlossaryChip(term: 'MC')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MC'), findsOneWidget);

    await tester.tap(find.byType(GlossaryChip));
    await tester.pumpAndSettle();

    // The definition dialog explains MC in plain English.
    expect(find.textContaining('primary character'), findsWidgets);
    expect(find.text('Close'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Close'), findsNothing);
  });

  testWidgets('GlossaryChip for an unknown term renders nothing visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GlossaryChip(term: 'ZZZ')),
      ),
    );
    await tester.pumpAndSettle();

    // The chip degrades to an empty box — no term text, no tap target.
    expect(find.text('ZZZ'), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('showGlossaryDialog lists every glossary term', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showGlossaryDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('What do these words mean?'), findsOneWidget);
    for (final entry in PorchGlossary.entries) {
      expect(
        find.text(entry.term),
        findsWidgets,
        reason: 'glossary should list ${entry.term}',
      );
    }
  });

  test('PorchGlossary defines MC, NPC and User in plain English', () {
    final byTerm = {for (final e in PorchGlossary.entries) e.term: e};
    expect(byTerm['MC']!.short, contains('Main Character'));
    expect(byTerm['NPC']!.short, contains('Non-Playable Character'));
    expect(byTerm['User']!.short, contains('account holder'));
    // Every entry has a real definition, not a stub.
    for (final e in PorchGlossary.entries) {
      expect(e.definition.length, greaterThan(20), reason: e.term);
    }
  });
}
