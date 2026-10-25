// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// AlicePressable fires taps and AliceSegmentedControl still switches
// after the GestureDetector -> AlicePressable swap.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/ui/alice/alice_motion.dart';
import 'package:front_porch_ai/ui/alice/alice_widgets.dart';

void main() {
  testWidgets('AlicePressable fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlicePressable(
            onTap: () => tapped = true,
            child: const Text('press me'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('press me'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('AlicePressable with null onTap does not crash', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AlicePressable(child: Text('disabled'))),
      ),
    );
    await tester.tap(find.text('disabled'));
    await tester.pump();
  });

  testWidgets('AliceSegmentedControl switches selection on tap', (
    tester,
  ) async {
    var selected = 'a';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AliceSegmentedControl<String>(
              values: const ['a', 'b'],
              labels: const ['A', 'B'],
              selected: selected,
              onChanged: (v) => setState(() => selected = v),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(selected, 'b');
  });
}
