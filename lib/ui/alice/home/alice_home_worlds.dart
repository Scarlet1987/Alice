// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Home: Worlds card. Part of alice_home.dart.
//
// Empty state per the approved preview (🌌 "No worlds yet" →
// "Build your first world"). Populated: every place world from
// WorldRepository as a labeled collapsible panel — roots on top,
// children drilled down under their parent, each row labeled with its
// hierarchy tier (Stage → Universe → Planet → Continent →
// City/Village/Town).

part of '../alice_home.dart';

extension _AliceHomeWorlds on _AliceHomeScreenState {
  Widget _buildWorldsCard(BuildContext context) {
    final worlds = context.watch<WorldRepository>().placeWorlds;
    return AliceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AliceSectionHead(
            title: 'Worlds',
            subtitle: 'Where your stories are set',
          ),
          const SizedBox(height: 10),
          if (worlds.isEmpty)
            _buildWorldsEmpty(context)
          else ...[
            for (final root in _homeWorldRoots(worlds))
              _buildWorldPanel(context, worlds, root, <String>{}),
            const SizedBox(height: 10),
            AliceButton(
              label: 'Open in Worlds',
              ghost: true,
              small: true,
              onPressed: () => Provider.of<AppState>(
                context,
                listen: false,
              ).setIndex(_aliceWorldsIndex),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorldsEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            const Opacity(
              opacity: 0.4,
              child: Text('🌌', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 12),
            const Text(
              'No worlds yet',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Every story needs a stage. Build your first world —\n'
              'pick a scale, set the physics, start creating.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 16),
            AliceButton(
              label: 'Build your first world',
              onPressed: () => Provider.of<AppState>(
                context,
                listen: false,
              ).setIndex(_aliceWorldsIndex),
            ),
          ],
        ),
      ),
    );
  }

  /// One world panel: a tier-labeled header row; worlds with children
  /// collapse/expand, and children render one level deeper (drill-down).
  Widget _buildWorldPanel(
    BuildContext context,
    List<World> all,
    World world,
    Set<String> seen,
  ) {
    if (!seen.add(world.id)) return const SizedBox.shrink();
    final children = _homeWorldChildren(all, world.id);
    if (children.isEmpty) {
      return ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        title: _worldPanelTitle(context, world),
        subtitle: _worldPanelSubtitle(context, world),
      );
    }
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      childrenPadding: const EdgeInsets.only(left: 16),
      shape: const Border(),
      collapsedShape: const Border(),
      title: _worldPanelTitle(context, world),
      subtitle: _worldPanelSubtitle(context, world),
      children: [
        for (final child in children)
          _buildWorldPanel(context, all, child, seen),
      ],
    );
  }

  Widget _worldPanelTitle(BuildContext context, World world) {
    return Row(
      children: [
        AliceChip(label: world.tier.label, color: AppColors.action),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            world.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget? _worldPanelSubtitle(BuildContext context, World world) {
    final description = world.description.trim();
    if (description.isEmpty) return null;
    return Text(
      description.split('\n').first,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Worlds with no parent in the store (same root rule as the Worlds
/// screen), plus any world unreachable from a root (orphaned parent
/// cycles) so nothing in the store is hidden.
List<World> _homeWorldRoots(List<World> worlds) {
  final byId = {for (final w in worlds) w.id: w};
  bool isRoot(World w) {
    final parentId = w.parentWorldId;
    return parentId == null ||
        parentId.isEmpty ||
        parentId == w.id ||
        !byId.containsKey(parentId);
  }

  final roots = [
    for (final w in worlds)
      if (isRoot(w)) w,
  ];
  final reachable = <String>{};
  void mark(World w) {
    if (!reachable.add(w.id)) return;
    for (final child in _homeWorldChildren(worlds, w.id)) {
      mark(child);
    }
  }

  for (final root in roots) {
    mark(root);
  }
  for (final w in worlds) {
    if (!reachable.contains(w.id)) roots.add(w);
  }
  roots.sort((a, b) {
    final byTier = a.tier.index.compareTo(b.tier.index);
    return byTier != 0 ? byTier : a.name.compareTo(b.name);
  });
  return roots;
}

/// Direct children of [parentId], tier order then name (mirrors the
/// Worlds screen's chain ordering).
List<World> _homeWorldChildren(List<World> worlds, String parentId) {
  final children = [
    for (final w in worlds)
      if (w.parentWorldId == parentId) w,
  ];
  children.sort((a, b) {
    final byTier = a.tier.index.compareTo(b.tier.index);
    return byTier != 0 ? byTier : a.name.compareTo(b.name);
  });
  return children;
}
