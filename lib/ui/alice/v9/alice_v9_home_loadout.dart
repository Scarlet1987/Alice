// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 Home: Pocket in Space Time holding the Starting Loadout 3x2.
// Split from alice_v9_home.dart to keep every file under 500 lines.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_inventory.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_state.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_widgets.dart';

/// Pocket in Space Time, holding the Starting Loadout fixed inside it.
/// One combined label, narrowed and centred in the width Home gives it
/// (max 1100px), 3x2 grid inside.
class LoadoutCard extends StatelessWidget {
  final AliceV9State state;
  final List<CharacterCard> characters;

  const LoadoutCard({
    super.key,
    required this.state,
    required this.characters,
  });

  @override
  Widget build(BuildContext context) {
    // Narrowed and centred, not stretched across the width it is
    // given: Center gives the card equal margins left and right,
    // ConstrainedBox caps it at 1100px so the 3-column grid stays
    // readable on a wide desktop window. In the wide branch Home gives
    // it the Stage+Char area right of the Jump rail, so it lines up
    // with those cards; in the narrow branch that width is the full
    // page. Below 1100px the cap does nothing — the card takes the
    // width the page gives it — and below 700px the grid inside still
    // stacks to one column. Both Home branches use this same card, so
    // both get the centred bar.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: V9Card(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const V9Heading('pocket in space time — starting loadout'),
          const SizedBox(height: 8),
          const V9Muted(
            'Pocket in Space Time is the container, and it holds Starting '
            'Loadout, fixed inside it — not dynamic, not empty. Top: '
            'weapons | armor | clothing. Bottom: accessories | items | '
            'quest items.',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final boxes = [
                _LoadoutBox(
                  title: 'weapons',
                  slots: const [
                    'weapons-intimate',
                    'weapons-close',
                    'weapons-long',
                  ],
                  state: state,
                  characters: characters,
                ),
                _LoadoutBox(
                  title: 'armor',
                  slots: const [
                    'armor-top',
                    'armor-helmet',
                    'armor-legs',
                  ],
                  state: state,
                  characters: characters,
                ),
                _LoadoutBox(
                  title: 'clothing',
                  slots: const [
                    'clothing-torso',
                    'clothing-chest',
                    'clothing-legs',
                    'clothing-arms',
                    'clothing-feet',
                    'clothing-hands',
                  ],
                  state: state,
                  characters: characters,
                ),
                _LoadoutBox(
                  title: 'accessories',
                  slots: const [
                    'accessory-1',
                    'accessory-2',
                    'accessory-3',
                    'accessory-4',
                  ],
                  state: state,
                  characters: characters,
                ),
                _LoadoutBox(
                  title: 'items',
                  slots: const [
                    'item-1',
                    'item-2',
                    'item-3',
                    'item-4',
                  ],
                  state: state,
                  characters: characters,
                ),
                _LoadoutBox(
                  title: 'quest items',
                  slots: const ['quest-1'],
                  state: state,
                  characters: characters,
                ),
              ];
              if (constraints.maxWidth < 700) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final box in boxes) ...[
                      box,
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var column = 0; column < 3; column++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: column == 0 ? 0 : 8,
                          right: column == 2 ? 0 : 8,
                        ),
                        child: Column(
                          children: [
                            boxes[column],
                            const SizedBox(height: 16),
                            boxes[column + 3],
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        ),
        ),
      ),
    );
  }
}

class _LoadoutBox extends StatelessWidget {
  final String title;
  final List<String> slots;
  final AliceV9State state;
  final List<CharacterCard> characters;

  const _LoadoutBox({
    required this.title,
    required this.slots,
    required this.state,
    required this.characters,
  });

  @override
  Widget build(BuildContext context) {
    return V9Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          V9Heading(title),
          const SizedBox(height: 12),
          for (final slot in slots)
            _SlotField(slot: slot, state: state, characters: characters),
        ],
      ),
    );
  }
}

class _SlotField extends StatelessWidget {
  final String slot;
  final AliceV9State state;
  final List<CharacterCard> characters;

  const _SlotField({
    required this.slot,
    required this.state,
    required this.characters,
  });

  @override
  Widget build(BuildContext context) {
    final def = kV9LoadoutSlots.firstWhere((s) => s.$1 == slot);
    final group = def.$3.first;
    final items = V9Inventory.itemsForSlot(characters, group);
    final isQuest = group == 'quest';
    // A stale pick (the item left the library) must not reach the
    // dropdown: Flutter asserts a dropdown value is in its item list,
    // so a stale one would crash the page. Show it empty instead.
    final pick = state.loadout[slot];
    final value = pick != null && items.contains(pick) ? pick : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: V9SlotDropdown(
        label: def.$2,
        items: items,
        value: value,
        onChanged: (v) => state.setLoadout(slot, v),
        emptyHint: isQuest
            ? 'No quest items yet'
            : 'No ${def.$2} items yet',
      ),
    );
  }
}
