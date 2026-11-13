// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 Home, restyled to the Alice Demo Space (2026-11-09, the
// entire design): header, nav with dead space, Jump To (6 items, in
// order), Stage Cover Flow +new/edit/-del, Current Char Cover Flow
// +new/edit/-del, then Pocket in Space Time holding the Starting
// Loadout 3x2, lined up under Stage / Current Char, and credits with
// FAQ at the foot. Stage and Current Char are the same size. Loadout
// dropdowns are fed by the selected character's owned items — never
// "Option 1".

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/services/character_repository.dart';
import 'package:front_porch_ai/services/storage_service.dart';
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
            final storage = Provider.of<StorageService>(context, listen: false);
            await Provider.of<CharacterRepository>(
              context,
              listen: false,
            ).deleteCharacter(
              character,
              worldRepo: Provider.of<WorldRepository>(context, listen: false),
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
        : stageNames
              .indexOf(state.selectedStageName ?? '')
              .clamp(0, stageNames.length - 1);
    CharacterCard? currentCharacter;
    for (final c in characters) {
      if (c.dbId == state.selectedCharacterId) currentCharacter = c;
    }
    currentCharacter ??= characters.isEmpty ? null : characters.first;
    final charNames = [for (final c in characters) c.name];
    final charIndex = currentCharacter == null || charNames.isEmpty
        ? 0
        : charNames
              .indexOf(currentCharacter.name)
              .clamp(0, charNames.length - 1);
    final loadoutCharacters = currentCharacter == null
        ? characters
        : [currentCharacter];
    // A final local, so the delete closure below sees a non-null card:
    // the analyzer cannot promote the reassigned `currentCharacter`.
    final characterToDelete = currentCharacter;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final stageCard = StageCard(
          state: state,
          stageNames: stageNames,
          stageIndex: stageIndex,
          stages: stages,
          onNew: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AliceWorldsScreen())),
          onEdit: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AliceWorldsScreen())),
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
          onDelete: characterToDelete == null
              ? null
              : () => _deleteCharacter(context, characterToDelete),
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
                const SizedBox(height: 16),
                const _CreditsSection(),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // IntrinsicHeight, not a bare stretch Row: the scroll view
                    // gives this Column infinite height, and a Row with
                    // CrossAxisAlignment.stretch under it tries to fill that
                    // infinite height — "BoxConstraints forces an infinite
                    // height" on first paint, and the never-laid-out boxes
                    // then fail every hit test. IntrinsicHeight measures the
                    // tallest card first, so stretch has a finite height to
                    // fill and Stage / Current Char stay the same height.
                    IntrinsicHeight(
                      child: Row(
                        // Stretch, not start: Stage and Current Char are the
                        // same height (preview v2 fix), button rows centred.
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 240,
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
                    ),
                    const SizedBox(height: 24),
                    // Pocket lines up with Stage / Current Char above it, not
                    // with the whole page: the same 240px Jump rail + 24px gap
                    // sits to its left, so it gets exactly the Stage+Char
                    // width. Its centre is their centre, and when it is
                    // narrower than them (the 1100px cap inside LoadoutCard)
                    // it is inset by equal margins on both sides.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 240),
                        const SizedBox(width: 24),
                        Expanded(child: loadout),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _CreditsSection(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Credits live here, with FAQ — not in the hero. No names are listed
/// yet; none are invented here.
class _CreditsSection extends StatelessWidget {
  const _CreditsSection();

  @override
  Widget build(BuildContext context) {
    return const V9Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          V9Heading('credits'),
          SizedBox(height: 8),
          V9Muted(
            'Hardware credits and software credits are kept here, with '
            'FAQ — no names are listed yet.',
          ),
        ],
      ),
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
              transform: Matrix4.translationValues(
                0,
                _headingHover ? -2 : 0,
                0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: const Text(
                'jump to',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'Cormorant Garamond',
                  fontFamilyFallback: ['Georgia'],
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.aliceMint,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // One straight stack: every target the same height and the full
          // rail width, one line each — no wrapping, no ragged pills.
          // `small` so the longest label ("faq definitions") fits on one
          // line inside the 240px rail.
          for (final target in kV9JumpTargets) ...[
            SizedBox(
              height: 44,
              child: V9Button(
                label: target.toLowerCase(),
                ghost: true,
                small: true,
                fillWidth: true,
                onPressed: () => widget.onJump(target),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.state.jumpNote.isNotEmpty) V9Muted(widget.state.jumpNote),
        ],
      ),
    );
  }
}
