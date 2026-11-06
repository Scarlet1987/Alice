// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 owned items (combined preview v9): loadout dropdowns are fed
// by real character cards, never "Option 1". Slot keywords, the worn /
// carrying fallback, and the quest-only rule live here — one place, so
// Home and any later screen filter the same way.

import 'package:front_porch_ai/models/models.dart';

/// Loadout slot definitions, in the preview's 3x2 grid order.
/// Each entry: (slot id, label, slot group).
const List<(String, String, List<String>)> kV9LoadoutSlots = [
  ('weapons-intimate', 'intimate', ['weapons']),
  ('weapons-close', 'close range', ['weapons']),
  ('weapons-long', 'long range', ['weapons']),
  ('armor-top', 'top armor', ['armor']),
  ('armor-helmet', 'helmet', ['armor']),
  ('armor-legs', 'leg armor', ['armor']),
  ('clothing-torso', 'torso', ['clothing']),
  ('clothing-chest', 'chest', ['clothing']),
  ('clothing-legs', 'legs', ['clothing']),
  ('clothing-arms', 'arms', ['clothing']),
  ('clothing-feet', 'feet', ['clothing']),
  ('clothing-hands', 'hands', ['clothing']),
  ('accessory-1', 'accessory 1', ['accessories']),
  ('accessory-2', 'accessory 2', ['accessories']),
  ('accessory-3', 'accessory 3', ['accessories']),
  ('accessory-4', 'accessory 4', ['accessories']),
  ('item-1', 'item 1', ['items']),
  ('item-2', 'item 2', ['items']),
  ('item-3', 'item 3', ['items']),
  ('item-4', 'item 4', ['items']),
  ('quest-1', 'quest item 1', ['quest']),
];

/// Keywords that put an owned item in a slot. An item that matches no
/// keyword falls back by where it lives: worn -> clothing, carrying ->
/// items. Quest items are only items a quest actually gave (see
/// [questItems]); anything else leaves that slot honestly empty.
const Map<String, List<String>> kV9SlotKeywords = {
  'weapons': [
    'sword', 'dagger', 'bow', 'axe', 'staff', 'spear', 'blade', 'gun',
    'rifle', 'pistol', 'wand', 'mace', 'knife', 'crossbow',
  ],
  'armor': [
    'helmet', 'helm', 'armor', 'armour', 'plate', 'shield', 'greaves',
    'gauntlet', 'pauldron', 'breastplate', 'chainmail', 'cuirass',
  ],
  'clothing': [
    'shirt', 'dress', 'robe', 'cloak', 'boot', 'shoe', 'glove', 'pants',
    'trouser', 'skirt', 'jacket', 'coat', 'hat', 'cap', 'tunic',
    'legging', 'sock', 'scarf', 'belt',
  ],
  'accessories': [
    'ring', 'amulet', 'necklace', 'earring', 'bracelet', 'collar',
    'charm', 'pendant', 'brooch', 'circlet',
  ],
  'items': [
    'potion', 'food', 'water', 'bread', 'torch', 'rope', 'map', 'key',
    'coin', 'gem', 'scroll', 'book', 'bandage', 'herb', 'elixir',
  ],
};

class V9Inventory {
  V9Inventory._();

  /// Every item any library character is wearing or carrying, from the
  /// card's stored inventory ({worn: [...], carrying: [...]}, entries a
  /// plain string or {name, state}). No invented items, no placeholders.
  static List<String> ownedItems(List<CharacterCard> characters) {
    final items = <String>{};
    for (final card in characters) {
      final inventory = card.frontPorchExtensions?.inventory;
      if (inventory == null) continue;
      for (final key in ['worn', 'carrying']) {
        final list = inventory[key];
        if (list is! List) continue;
        for (final entry in list) {
          final name = _itemName(entry);
          if (name.isNotEmpty) items.add(name);
        }
      }
    }
    final sorted = items.toList()..sort();
    return sorted;
  }

  static String _itemName(Object? entry) {
    if (entry is String) return entry.trim();
    if (entry is Map) {
      final name = entry['name'];
      final state = entry['state'];
      if (name is String && name.trim().isNotEmpty) {
        return state is String && state.trim().isNotEmpty
            ? '${name.trim()} (${state.trim()})'
            : name.trim();
      }
    }
    return '';
  }

  /// Items for one slot: keyword matches first; unmatched worn items
  /// fall back to clothing, unmatched carrying items to items. Quest
  /// items never fall back — see [questItems].
  static List<String> itemsForSlot(
    List<CharacterCard> characters,
    String slot,
  ) {
    if (slot == 'quest') return questItems(characters);
    final keywords = kV9SlotKeywords[slot] ?? const [];
    final worn = <String>[];
    final carrying = <String>[];
    for (final card in characters) {
      final inventory = card.frontPorchExtensions?.inventory;
      if (inventory == null) continue;
      for (final entry in (inventory['worn'] as List? ?? const [])) {
        final name = _itemName(entry);
        if (name.isNotEmpty) worn.add(name);
      }
      for (final entry in (inventory['carrying'] as List? ?? const [])) {
        final name = _itemName(entry);
        if (name.isNotEmpty) carrying.add(name);
      }
    }
    bool matches(String name) {
      final lower = name.toLowerCase();
      return keywords.any(lower.contains);
    }

    final matched = [
      ...worn.where(matches),
      ...carrying.where(matches),
    ];
    if (matched.isNotEmpty) return matched.toSet().toList()..sort();
    if (slot == 'clothing') return worn.toSet().toList()..sort();
    if (slot == 'items') return carrying.toSet().toList()..sort();
    return const [];
  }

  /// Only items a quest actually gave: an inventory entry flagged
  /// {quest: true} or named as a quest item. Otherwise honestly empty —
  /// never "Option 1".
  static List<String> questItems(List<CharacterCard> characters) {
    final found = <String>{};
    for (final card in characters) {
      final inventory = card.frontPorchExtensions?.inventory;
      if (inventory == null) continue;
      for (final key in ['worn', 'carrying']) {
        final list = inventory[key];
        if (list is! List) continue;
        for (final entry in list) {
          if (entry is Map && entry['quest'] == true) {
            final name = _itemName(entry);
            if (name.isNotEmpty) found.add(name);
          } else if (entry is String &&
              entry.toLowerCase().contains('quest')) {
            found.add(entry.trim());
          }
        }
      }
    }
    final sorted = found.toList()..sort();
    return sorted;
  }
}
