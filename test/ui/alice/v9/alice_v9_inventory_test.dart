// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 loadout lists: dropdowns are fed by real character cards,
// never "Option 1". Quest items only ever come from a quest.
// UNRUN in the VM that wrote it (no Flutter/Dart there) — run on metal:
//   flutter test test/ui/alice/v9/alice_v9_inventory_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_identity.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_inventory.dart';

CharacterCard _card(Map<String, dynamic> inventory) => CharacterCard(
  name: 'Test',
  frontPorchExtensions: FrontPorchExtensions(inventory: inventory),
);

void main() {
  group('V9Inventory', () {
    test('owned items come from worn + carrying, sorted, de-duplicated', () {
      final cards = [
        _card({
          'worn': ['iron sword', 'leather boots'],
          'carrying': ['health potion', 'iron sword'],
        }),
      ];
      expect(
        V9Inventory.ownedItems(cards),
        ['health potion', 'iron sword', 'leather boots'],
      );
    });

    test('empty library means honestly empty lists, never a placeholder', () {
      expect(V9Inventory.ownedItems(const []), isEmpty);
      expect(V9Inventory.itemsForSlot(const [], 'weapons'), isEmpty);
      expect(V9Inventory.questItems(const []), isEmpty);
    });

    test('weapons slot matches by keyword', () {
      final cards = [
        _card({
          'worn': ['iron sword'],
          'carrying': ['health potion'],
        }),
      ];
      expect(
        V9Inventory.itemsForSlot(cards, 'weapons'),
        ['iron sword'],
      );
      expect(
        V9Inventory.itemsForSlot(cards, 'items'),
        ['health potion'],
      );
    });

    test('quest items only come from a quest', () {
      final cards = [
        _card({
          'worn': ['iron sword'],
          'carrying': [
            'health potion',
            {'name': 'Sunken Crown', 'quest': true},
          ],
        }),
      ];
      expect(V9Inventory.questItems(cards), ['Sunken Crown']);
      expect(
        V9Inventory.itemsForSlot(cards, 'quest'),
        ['Sunken Crown'],
      );
    });

    test('a card with no inventory contributes nothing', () {
      final cards = [CharacterCard(name: 'Bare')];
      expect(V9Inventory.ownedItems(cards), isEmpty);
    });
  });

  group('V9Identity', () {
    test('a picked value resolves to itself', () {
      expect(V9Identity(pick: 'male').resolved, 'male');
      expect(V9Identity(pick: 'they/them').resolved, 'they/them');
    });

    test('custom resolves to the typed value, and only when typed', () {
      expect(V9Identity(pick: 'custom', custom: 'xe/xem').resolved, 'xe/xem');
      expect(V9Identity(pick: 'custom', custom: '  ').resolved, 'custom');
    });

    test('a custom value round-trips through JSON', () {
      final original = V9Identity(pick: 'custom', custom: 'fae/faer');
      final restored = V9Identity.fromJson(original.toJson());
      expect(restored.pick, 'custom');
      expect(restored.resolved, 'fae/faer');
    });
  });
}
