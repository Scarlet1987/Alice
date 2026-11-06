// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 Home (combined preview v9): header, nav with dead space,
// Jump To (6 items, in order), Stage Cover Flow +new/edit/-del, Current
// Char Cover Flow +new/edit/-del, then Pocket in Space Time holding the
// Starting Loadout 3x2, stretched fully across. Stage and Current Char
// are the same size, their button rows centred. The Jump To heading lifts
// on hover like a button. Loadout dropdowns are fed by the selected
// character's owned items — never "Option 1".

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/services/character_repository.dart';
import 'package:front_porch_ai/services/storage/storage.dart';
import 'package:front_porch_ai/services/world_repository.dart';
import 'package:front_porch_ai/ui/alice/alice_worlds.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_state.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_home_cards.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_home_loadout.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/widgets/warm_dialog.dart';

/// Jump To targets, in the preview's order. Targets that are not placed
/// yet in the sketch say so instead of pretending to jump somewhere.
const List<String> kV9JumpTargets = [
  'World lore',
  'Equip',
  'Char card',
  'FAQ definitions',
  'Benchmark',
  'Start server',
];

class AliceV9HomePage extends StatelessWidget {
  final AliceV9State state;
  final GlobalKey _loadoutKey = GlobalKey();
  final GlobalKey _charKey = GlobalKey();

  AliceV9HomePage({super.key, required this.state});

  void _jump(BuildContext context, String target) {
    switch (target) {
      case 'Equip':
        final loadoutContext = _loadoutKey.currentContext;
        if (loadoutContext != null) {
          Scrollable.ensureVisible(
            loadoutContext,
            duration: const Duration(milliseconds: 300),
          );
        }
        state.note('Equip — the Starting Loadout below.');
      case 'Char card':
        final charContext = _charKey.currentContext;
        if (charContext != null) {
          Scrollable.ensureVisible(
            charContext,
            duration: const Duration(milliseconds: 300),
          );
        }
        state.note('Char card — the Current Char above.');
      case 'World lore':
        state.note(
          'World lore — lore lives on the Worlds screen, not on Home.',
        );
      default:
        // FAQ definitions, Benchmark, Start server: not placed yet in
        // the sketch, and the preview says so rather than inventing a
        // destination for them.
        state.note(
          '$target — not placed yet in this sketch. Tell me where it goes.',
        );
    }
  }

  Future<void> _deleteStage(BuildContext context, World stage) async {
    await showWarmDialog<void>(
      context,
      title: 'Delete stage?',
      content: Text('Delete the stage "${stage.name}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep it'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await Provider.of<WorldRepository>(
              context,
              listen: false,
            ).deleteWorld(stage);
            state.selectStage(null);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted stage "${stage.name}".')),
              );
            }
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }

  Future<void> _deleteCharacter(
    BuildContext context,
    CharacterCard character,
  ) async {
    await showWarmDialog<void>(
      context,
      title: 'Delete character?',
      content: Text('Delete "${character.name}" from the library?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep it'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final storage = Provider.of<StorageService>(
              context,
              listen: false,
            );
            await Provider.of<CharacterRepository>(
              context,
              listen: false,
            ).deleteCharacter(
              character,
              worldRepo: Provider.of<WorldRepository>(
                context,
                listen: false,
              ),
              chatsDir: storage.chatsDir,
            );
            state.selectCharacter(null);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "${character.name}".')),
              );
            }
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final characters = context.watch<CharacterRepository>().characters;
    final stages = context.watch<WorldRepository>().placeWorlds;
    final stageNames = [for (final stage in stages) stage.name];
    final stageIndex = stageNames.isEmpty
        ? 0
        : stageNames.indexOf(state.selectedStageName ?? '').clamp(
            0,
            stageNames.length - 1,
          );
    CharacterCard? currentCharacter;
    for (final c in characters) {
      if (c.dbId == state.selectedCharacterId) currentCharacter = c;
    }
    currentCharacter ??= characters.isEmpty ? null : characters.first;
    final charNames = [for (final c in characters) c.name];
    final charIndex = currentCharacter == null || charNames.isEmpty
        ? 0
        : charNames.indexOf(currentCharacter.name).clamp(
            0,
            charNames.length - 1,
          );
    final loadoutCharacters = currentCharacter == null
        ? characters
        : [currentCharacter];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final stageCard = StageCard(
          state: state,
          stageNames: stageNames,
          stageIndex: stageIndex,
          stages: stages,
          onNew: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AliceWorldsScreen()),
          ),
          onEdit: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AliceWorldsScreen()),
          ),
          onDelete: stages.isEmpty
              ? null
              : () => _deleteStage(context, stages[stageIndex]),
        );
        final charCard = CharCard(
          key: _charKey,
          state: state,
          charNames: charNames,
          charIndex: charIndex,
          character: currentCharacter,
          onNew: () => state.setPage(V9Page.creator),
          onEdit: () => state.setPage(V9Page.creator),
          onDelete: currentCharacter == null
              ? null
              : () => _deleteCharacter(context, currentCharacter),
        );
        final loadout = LoadoutCard(
          key: _loadoutKey,
          state: state,
          characters: loadoutCharacters,
        );
        if (!wide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _JumpRail(state: state, onJump: (t) => _jump(context, t)),
                const SizedBox(height: 16),
                stageCard,
                const SizedBox(height: 16),
                charCard,
                const SizedBox(height: 16),
                loadout,
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                // Stretch, not start: Stage and Current Char are the same
                // height (preview v2 fix), their button rows centred.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 270,
                    child: _JumpRail(
                      state: state,
                      onJump: (t) => _jump(context, t),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: stageCard),
                  const SizedBox(width: 24),
                  Expanded(child: charCard),
                ],
              ),
              const SizedBox(height: 24),
              loadout,
            ],
          ),
        );
      },
    );
  }
}

/// Jump To rail: the heading lifts on hover like a button (preview v9
/// fix), then the six targets in order.
class _JumpRail extends StatefulWidget {
  final AliceV9State state;
  final ValueChanged<String> onJump;

  const _JumpRail({required this.state, required this.onJump});

  @override
  State<_JumpRail> createState() => _JumpRailState();
}

class _JumpRailState extends State<_JumpRail> {
  bool _headingHover = false;

  @override
  Widget build(BuildContext context) {
    return V9Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MouseRegion(
            onEnter: (_) => setState(() => _headingHover = true),
            onExit: (_) => setState(() => _headingHover = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.translationValues(0, _headingHover ? -2 : 0, 0),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.aliceGreen,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.aliceEdge,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: AppColors.pureBlack.withValues(
                      alpha: _headingHover ? 0.3 : 0.25,
                    ),
                    offset: const Offset(0, 5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Text(
                'jump to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pureWhite,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final target in kV9JumpTargets) ...[
            V9Button(
              label: target.toLowerCase(),
              onPressed: () => widget.onJump(target),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.state.jumpNote.isNotEmpty)
            V9Muted(widget.state.jumpNote),
        ],
      ),
    );
  }
}


