// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Worlds, rebuilt from Elaina's 2026-10-25 sketch and the condensed
// preview: a centred Stage container holding Jump to, the How worlds
// work rules, and one closed-by-default tier section per tier. Real
// place data only, from WorldRepository.placeWorlds. No Stage
// description line and no empty-state card: both were deleted from
// the preview, so an empty store simply shows the tier sections with
// their + controls to start.
//
// Two model notes, both deliberate and reversible. The sketch ladder
// includes Galaxy, which the store had no tier for, so WorldTier
// gained galaxy (tier is a string in placeTraits, not a Drift column,
// so no migration; an older build reading "galaxy" falls back to
// planet). City, Village, and Town are one stored settlement tier,
// so a settlement world carries a settlementKind placeTrait; a world
// without one shows in all three sections, labelled unsorted, until
// it is edited to one kind — nothing is hidden, nothing is guessed.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/models/lorebook.dart';
import 'package:front_porch_ai/models/world.dart' as world_model;
import 'package:front_porch_ai/providers/app_state.dart';
import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/ui/alice/alice_forest_background.dart';
import 'package:front_porch_ai/ui/alice/alice_widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/widgets/warm_dialog.dart';

part 'worlds/alice_worlds_sections.dart';
part 'worlds/alice_worlds_dialog.dart';

class AliceWorldsScreen extends StatefulWidget {
  const AliceWorldsScreen({super.key});

  @override
  State<AliceWorldsScreen> createState() => _AliceWorldsScreenState();
}

class _AliceWorldsScreenState extends State<AliceWorldsScreen> {
  final _scrollController = ScrollController();
  final _sectionKeys = {
    for (final section in _WorldsSection.values) section: GlobalKey(),
  };
  final _openSections = <_WorldsSection>{};
  String? _selectedWorldId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// World position, for real: open [section], select [worldId] if
  /// given, and scroll to the section after the frame lands.
  void _focusSection(_WorldsSection section, {String? worldId}) {
    setState(() {
      _openSections.add(section);
      if (worldId != null) _selectedWorldId = worldId;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _sectionKeys[section]?.currentContext;
      if (context != null && mounted) {
        Scrollable.ensureVisible(context, duration: Durations.short4);
      }
    });
  }

  void _jumpTo(_WorldsSection section) => _focusSection(section);

  void _focusAdjacentAfterDelete(
    _WorldsSection section,
    List<world_model.World> before,
    String deletedId,
  ) {
    final index = before.indexWhere((w) => w.id == deletedId);
    world_model.World? adjacent;
    if (index >= 0) {
      if (index + 1 < before.length) {
        adjacent = before[index + 1];
      } else if (index > 0) {
        adjacent = before[index - 1];
      }
    }
    _focusSection(section, worldId: adjacent?.id);
    if (adjacent == null) setState(() => _selectedWorldId = null);
  }

  Future<void> _addWorld(
    WorldRepository repo,
    List<world_model.World> all, {
    required _WorldsSection section,
    world_model.World? parent,
  }) async {
    final created = await showWarmDialogOf<world_model.World>(
      context,
      builder: (_) => _WorldDialog(
        initialSection: section,
        initialParent: parent,
        allWorlds: all,
      ),
    );
    if (created == null || !mounted) return;
    await repo.saveWorld(created);
    if (!mounted) return;
    final target = _WorldsSection.forWorld(created) ?? section;
    _focusSection(target, worldId: created.id);
  }

  Future<void> _editWorld(
    WorldRepository repo,
    List<world_model.World> all,
    world_model.World world, {
    _WorldsSection? fromSection,
  }) async {
    final edited = await showWarmDialogOf<world_model.World>(
      context,
      builder: (_) => _WorldDialog(
        existing: world,
        initialSection:
            fromSection ??
            _WorldsSection.forWorld(world) ??
            _WorldsSection.planet,
        allWorlds: all,
      ),
    );
    if (edited == null || !mounted) return;
    await repo.saveWorld(edited);
    if (!mounted) return;
    final target = _WorldsSection.forWorld(edited) ?? _WorldsSection.planet;
    _focusSection(target, worldId: edited.id);
  }

  Future<void> _deleteWorld(
    WorldRepository repo,
    List<world_model.World> all,
    world_model.World world,
  ) async {
    final confirmed = await showWarmDialog<bool>(
      context,
      title: 'Delete ${world.name}?',
      destructive: true,
      content: const WarmDialogText(
        'This deletes the world itself. Worlds under it are not '
        'deleted; they become top-level until you give them a parent.',
      ),
      actions: [
        warmDialogCancel(context),
        warmDialogConfirm(
          context,
          label: 'Delete',
          destructive: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;
    final section = _WorldsSection.forWorld(world);
    final before = section == null
        ? <world_model.World>[]
        : _sectionWorlds(section, all);
    await repo.deleteWorld(world);
    if (!mounted) return;
    if (section != null) {
      _focusAdjacentAfterDelete(section, before, world.id);
    } else {
      setState(() => _selectedWorldId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final worlds = context.watch<WorldRepository>().placeWorlds;
    final repo = context.read<WorldRepository>();
    final selected = _selectedWorldId == null
        ? null
        : worlds.where((w) => w.id == _selectedWorldId).firstOrNull;
    return AliceForestBackground(
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 18),
            AliceTranslucentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStageHead(context, repo, worlds, selected),
                  const SizedBox(height: 18),
                  _buildJumpTo(context),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 800) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildRules(context),
                            const SizedBox(height: 18),
                            _buildBoard(context, repo, worlds),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 300, child: _buildRules(context)),
                          const SizedBox(width: 18),
                          Expanded(child: _buildBoard(context, repo, worlds)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/rabbit-hole-icon/128.png',
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const SizedBox(
              width: 96,
              height: 96,
              child: Icon(Icons.public_rounded, size: 48),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Worlds',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Where your stories are set.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Centred Stage head: heading on top, three equal finished
  /// buttons below it. No Stage + / - buttons, by Elaina's deletion.
  Widget _buildStageHead(
    BuildContext context,
    WorldRepository repo,
    List<world_model.World> worlds,
    world_model.World? selected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Stage',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AliceButton(
                label: '+ new world',
                icon: Icons.add_rounded,
                onPressed: () =>
                    _addWorld(repo, worlds, section: _WorldsSection.universe),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AliceButton(
                label: 'edit world',
                ghost: true,
                icon: Icons.edit_rounded,
                onPressed: selected == null
                    ? null
                    : () => _editWorld(repo, worlds, selected),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AliceDangerButton(
                label: 'delete',
                icon: Icons.delete_rounded,
                onPressed: selected == null
                    ? null
                    : () => _deleteWorld(repo, worlds, selected),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJumpTo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AliceSectionHead(title: 'Jump to'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final section in _WorldsSection.values)
              AliceButton(
                label: section.title,
                ghost: true,
                small: true,
                icon: section.icon,
                onPressed: () => _jumpTo(section),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRules(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        border: Border.all(color: AppColors.borderSoftOf(context)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AliceSectionHead(title: 'How worlds work'),
          const SizedBox(height: 8),
          _rule(
            context,
            'World position.',
            'After an add, focus lands on the changed section. After a '
                'delete, focus lands on what is adjacent to it — because '
                'where you start the story is where you are.',
          ),
          _rule(
            context,
            'Name it yourself.',
            'Pressing + at any level prompts you to name that level. '
                'The AI never fills it in for you, and each scale you '
                'add is the boundary of what can be played in.',
          ),
          _rule(
            context,
            'Every field is + − your text.',
            'Every field carries + to add an instance and − to remove '
                'one, with your own text in it. At least one entry is kept.',
          ),
          Text(
            'Nothing hidden. No show-all gates. Labels are always '
            'visible; depth comes from scrolling and from these '
            'collapsible sections.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderSoftOf(context)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 20,
                  color: AppColors.porchAmberOf(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => context.read<AppState>().setIndex(2),
                    child: Text(
                      'Lore Book lives in creator. The full lore book is '
                      'in Creator\u2019s World section. Worlds is the '
                      'place ladder itself.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rule(BuildContext context, String title, String body) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$title ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(
    BuildContext context,
    WorldRepository repo,
    List<world_model.World> worlds,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in _WorldsSection.values)
          _TierSection(
            key: _sectionKeys[section],
            section: section,
            open: _openSections.contains(section),
            onHeaderTap: () => setState(() {
              if (_openSections.contains(section)) {
                _openSections.remove(section);
              } else {
                _openSections.add(section);
              }
            }),
            worlds: _sectionWorlds(section, worlds),
            allWorlds: worlds,
            selectedWorldId: _selectedWorldId,
            onSelect: (world) => setState(() => _selectedWorldId = world.id),
            onAdd: () => _addWorld(repo, worlds, section: section),
            onAddChild: (parent) {
              final child = _childSection(section);
              if (child == null) return;
              _addWorld(repo, worlds, section: child, parent: parent);
            },
            onEdit: (world) =>
                _editWorld(repo, worlds, world, fromSection: section),
            onDelete: (world) => _deleteWorld(repo, worlds, world),
          ),
      ],
    );
  }
}
