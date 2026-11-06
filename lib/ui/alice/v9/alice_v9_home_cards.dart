// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 Home: Stage and Current Char cards (Cover Flow +new/edit/-del).
// Split from alice_v9_home.dart to keep every file under 500 lines.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/services/character_repository.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_state.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_widgets.dart';

class StageCard extends StatelessWidget {
  final AliceV9State state;
  final List<String> stageNames;
  final int stageIndex;
  final List<World> stages;
  final VoidCallback onNew;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const StageCard({
    super.key,
    required this.state,
    required this.stageNames,
    required this.stageIndex,
    required this.stages,
    required this.onNew,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return V9Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const V9Heading('stage'),
          const SizedBox(height: 16),
          if (stageNames.isEmpty)
            const V9Muted(
              'No stages yet — create a world on the Worlds screen first.',
            )
          else
            V9CoverFlow(
              items: stageNames,
              selected: stageIndex,
              onSelect: (i) => state.selectStage(stageNames[i]),
              emptyText: 'No stages yet.',
            ),
          const SizedBox(height: 8),
          const V9Muted('Cover Flow, centered.'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              V9Button(label: '+new', small: true, onPressed: onNew),
              const SizedBox(width: 10),
              V9Button(label: 'edit', small: true, onPressed: onEdit),
              const SizedBox(width: 10),
              V9Button(label: '-del', small: true, onPressed: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

class CharCard extends StatelessWidget {
  final AliceV9State state;
  final List<String> charNames;
  final int charIndex;
  final CharacterCard? character;
  final VoidCallback onNew;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const CharCard({
    super.key,
    required this.state,
    required this.charNames,
    required this.charIndex,
    required this.character,
    required this.onNew,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return V9Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const V9Heading('current char'),
          const SizedBox(height: 16),
          if (charNames.isEmpty)
            const V9Muted(
              'No characters yet — make one in Char creator first.',
            )
          else
            V9CoverFlow(
              items: charNames,
              selected: charIndex,
              onSelect: (i) {
                final card = context
                    .read<CharacterRepository>()
                    .characters[i];
                state.selectCharacter(card.dbId);
              },
              emptyText: 'No characters yet.',
            ),
          const SizedBox(height: 8),
          const V9Muted('Cover Flow, centered.'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              V9Button(label: '+new', small: true, onPressed: onNew),
              const SizedBox(width: 10),
              V9Button(label: 'edit', small: true, onPressed: onEdit),
              const SizedBox(width: 10),
              V9Button(label: '-del', small: true, onPressed: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

