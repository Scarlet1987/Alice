// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Character Creator: the "World" section — universe down to
// village, plus the lore book grown from save state.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/alice/alice_creator_draft.dart';
import 'package:front_porch_ai/ui/alice/alice_creator_fields.dart';

/// "World": where the character lives, widest to narrowest.
class McWorldSection extends StatelessWidget {
  final AliceCreatorDraft draft;

  const McWorldSection({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AliceTextField(label: 'Universe name', controller: draft.universe),
        const SizedBox(height: 10),
        AliceTextField(label: 'Planet name', controller: draft.planet),
        const SizedBox(height: 10),
        AliceTextField(label: 'Continent name', controller: draft.continent),
        const SizedBox(height: 10),
        AliceTextField(
          label: 'City name',
          controller: draft.city,
          hint: 'The nearest city, if the story has one…',
        ),
        const SizedBox(height: 10),
        AliceTextField(label: 'Village name', controller: draft.village),
        const AliceAreaLabel('Lore book'),
        Text(
          'Built from your save state: pin what\u2019s important as you '
          'play, and the world stays consistent session to session.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 8),
        AliceTextField(
          label: 'Lorebook links',
          controller: draft.lorebookLinks,
          hint: 'e.g. The Meridian Bell · Ember War · Gullwatch',
        ),
      ],
    );
  }
}
