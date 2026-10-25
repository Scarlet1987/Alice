// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice edition Worlds screen: real place data from WorldRepository,
// rendered as tier chains (Stage → Universe → Planet → Continent →
// City/Village/Town). No mock data — empty state when no worlds exist.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/models/lorebook.dart';
import 'package:front_porch_ai/models/world.dart' as world_model;
import 'package:front_porch_ai/providers/app_state.dart';
import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/storage/settings/detail_level.dart';
import 'package:front_porch_ai/ui/alice/alice_widgets.dart';

/// Alice Worlds: every place world from the real world store, grouped into
/// hierarchy chains by root (a world with no parent in the store).
class AliceWorldsScreen extends StatelessWidget {
  const AliceWorldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<WorldRepository, CharacterRepository, StorageService>(
      builder: (context, worldRepo, charRepo, storage, _) {
        final places = worldRepo.placeWorlds;
        final detail = storage.uiSettings.detailLevel;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            _PageHeader(
              onNewWorld: () => _showNewWorldDialog(context, worldRepo),
            ),
            const SizedBox(height: 14),
            if (places.isEmpty)
              _EmptyState(
                onNewWorld: () => _showNewWorldDialog(context, worldRepo),
              ),
            for (final chain in _rootChains(places))
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _WorldCard(
                  chain: chain,
                  characterCount: (world_model.World w) => charRepo.characters
                      .where((c) => c.worldNames.contains(w.name))
                      .length,
                ),
              ),
            if (detail == DetailLevel.advanced) _contextPagingCard(),
          ],
        );
      },
    );
  }
}

/// One root world plus its descendant rows, depth-first, cycle-safe.
class _ChainRow {
  final world_model.World world;
  final int depth;
  const _ChainRow(this.world, this.depth);
}

List<List<_ChainRow>> _rootChains(List<world_model.World> worlds) {
  final byId = {for (final w in worlds) w.id: w};
  final roots = <world_model.World>[];
  final seen = <String>{};
  for (final w in worlds) {
    final parentId = w.parentWorldId;
    if (parentId == null ||
        parentId.isEmpty ||
        !byId.containsKey(parentId) ||
        parentId == w.id) {
      if (seen.add(w.id)) roots.add(w);
    }
  }
  // Orphaned cycles (no reachable root): show them as their own card.
  for (final w in worlds) {
    if (seen.add(w.id)) roots.add(w);
  }

  final childrenOf = <String, List<world_model.World>>{};
  for (final w in worlds) {
    final parentId = w.parentWorldId;
    if (parentId != null && parentId.isNotEmpty && byId.containsKey(parentId)) {
      childrenOf.putIfAbsent(parentId, () => []).add(w);
    }
  }
  for (final kids in childrenOf.values) {
    kids.sort(
      (a, b) => a.tier.index.compareTo(b.tier.index) != 0
          ? a.tier.index.compareTo(b.tier.index)
          : a.name.compareTo(b.name),
    );
  }

  final chains = <List<_ChainRow>>[];
  for (final root in roots) {
    final rows = <_ChainRow>[];
    final visited = <String>{};
    void walk(world_model.World w, int depth) {
      if (!visited.add(w.id)) return;
      rows.add(_ChainRow(w, depth));
      for (final kid in childrenOf[w.id] ?? const []) {
        walk(kid, depth + 1);
      }
    }

    walk(root, 0);
    chains.add(rows);
  }
  return chains;
}

class _PageHeader extends StatelessWidget {
  final VoidCallback onNewWorld;

  const _PageHeader({required this.onNewWorld});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AliceScreenTitle(title: 'Worlds'),
              const SizedBox(height: 4),
              Text(
                'Widest to narrowest. Descriptions live on disk and page into '
                'the story only when a scene needs them — your detail level '
                'decides how deep.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AliceButton(label: 'New world', onPressed: onNewWorld),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onNewWorld;

  const _EmptyState({required this.onNewWorld});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AliceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AliceSectionHead(
            title: 'No worlds yet',
            subtitle: 'Build your first place to start mapping it out',
          ),
          const SizedBox(height: 8),
          Text(
            'Worlds nest widest to narrowest: Stage → Universe → Planet → '
            'Continent → City/Village/Town. Add a top-level world first, '
            'then hang places beneath it.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 12),
          AliceButton(label: 'New world', onPressed: onNewWorld, block: true),
        ],
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  final List<_ChainRow> chain;
  final int Function(world_model.World) characterCount;

  const _WorldCard({required this.chain, required this.characterCount});

  @override
  Widget build(BuildContext context) {
    final root = chain.first.world;
    final breadcrumb = chain.map((r) => r.world.tier.label).toSet().join(' → ');
    return AliceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AliceSectionHead(title: root.name, subtitle: breadcrumb),
          for (final row in chain)
            _TierRow(
              world: row.world,
              depth: row.depth,
              characterCount: characterCount(row.world),
            ),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  final world_model.World world;
  final int depth;
  final int characterCount;

  const _TierRow({
    required this.world,
    required this.depth,
    required this.characterCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lorebookCount = world.lorebook.entries.length;
    return Padding(
      padding: EdgeInsets.only(left: depth * 18.0, top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              world.tier.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  world.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (world.description.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      world.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AliceChip(
                        label:
                            '$characterCount ${characterCount == 1 ? 'character' : 'characters'} here',
                      ),
                      AliceChip(
                        label:
                            '$lorebookCount ${lorebookCount == 1 ? 'lorebook entry' : 'lorebook entries'}',
                      ),
                      AliceButton(
                        label: 'Visit in chat',
                        ghost: true,
                        small: true,
                        onPressed: () => context.read<AppState>().setIndex(1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Advanced-only: how much of the hierarchy enters context per scene.
Widget _contextPagingCard() {
  return const AliceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AliceSectionHead(
          title: 'Context paging',
          subtitle:
              'How much of the hierarchy enters context per scene, by detail level',
        ),
        SizedBox(height: 8),
        AliceKeyValue(label: 'Simple', value: "Current town + the MC's card"),
        AliceKeyValue(
          label: 'Balanced',
          value: 'Town + continent, lorebook on keyword',
        ),
        AliceKeyValue(
          label: 'Advanced',
          value: 'Full chain, paged on demand per scene',
        ),
      ],
    ),
  );
}

/// Create-a-world dialog: name, tier, description. Saves into the real
/// world store via [WorldRepository.saveWorld].
void _showNewWorldDialog(BuildContext context, WorldRepository repo) {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  var tier = world_model.WorldTier.planet;

  showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Text('New world'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<world_model.WorldTier>(
                  // ignore: deprecated_member_use
                  value: tier,
                  decoration: const InputDecoration(labelText: 'Tier'),
                  items: [
                    for (final t in world_model.WorldTier.values)
                      DropdownMenuItem(value: t, child: Text(t.label)),
                  ],
                  onChanged: (t) => setDialogState(() => tier = t ?? tier),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hang more places under this one from the world library.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final world = world_model.World(
                  name: name,
                  description: descController.text.trim(),
                  lorebook: Lorebook(entries: []),
                )..tier = tier;
                repo.saveWorld(world);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save world'),
            ),
          ],
        );
      },
    ),
  );
}
