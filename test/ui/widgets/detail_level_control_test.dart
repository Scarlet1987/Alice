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

// The detail-level segmented control: it renders all three options and
// persists the user's choice through UiSettings.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/storage/storage.dart';
import 'package:front_porch_ai/ui/widgets/detail_level_control.dart';

void _setupPathProviderMock() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    if (methodCall.method == 'getApplicationDocumentsDirectory') {
      return Directory.systemTemp.createTempSync('fpai_detail_ctl_').path;
    }
    return null;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    _setupPathProviderMock();
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.initialized;
  });

  Widget harness() {
    return ChangeNotifierProvider<StorageService>.value(
      value: storage,
      child: const MaterialApp(home: Scaffold(body: DetailLevelControl())),
    );
  }

  testWidgets('renders the friendly prompt and all three options', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('How much detail do you want?'), findsOneWidget);
    expect(find.text('Simple'), findsOneWidget);
    expect(find.text('Balanced'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
  });

  testWidgets('tapping Advanced persists the choice', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(storage.uiSettings.detailLevel, DetailLevel.balanced);

    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();

    expect(storage.uiSettings.detailLevel, DetailLevel.advanced);
  });

  testWidgets('tapping Simple persists the choice', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simple'));
    await tester.pumpAndSettle();

    expect(storage.uiSettings.detailLevel, DetailLevel.simple);
  });

  testWidgets('DetailGate shows child inline at or above required level', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<StorageService>.value(
        value: storage,
        child: const MaterialApp(
          home: Scaffold(
            body: DetailGate(
              required: DetailLevel.balanced,
              child: Text('gated content'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default is balanced: content shows inline, no expander needed.
    expect(find.text('gated content'), findsOneWidget);
    expect(find.text('Show advanced options'), findsNothing);
  });

  testWidgets('DetailGate hides content behind an expander below the level', (
    tester,
  ) async {
    await storage.uiSettings.setDetailLevel(DetailLevel.simple);
    await tester.pumpWidget(
      ChangeNotifierProvider<StorageService>.value(
        value: storage,
        child: const MaterialApp(
          home: Scaffold(
            body: DetailGate(
              required: DetailLevel.balanced,
              child: Text('gated content'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Simple mode: the content is behind the expander, never gone.
    expect(find.text('Show advanced options'), findsOneWidget);
    expect(find.text('gated content'), findsNothing);

    await tester.tap(find.text('Show advanced options'));
    await tester.pumpAndSettle();
    expect(find.text('gated content'), findsOneWidget);
  });
}
