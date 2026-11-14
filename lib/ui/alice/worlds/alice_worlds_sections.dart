// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Worlds: tier sections. Part of alice_worlds.dart.

part of '../alice_worlds.dart';

/// One Jump-to section, in the preview's order. City, Village, and
/// Town share the stored settlement tier and differ by settlementKind.
enum _WorldsSection {
  universe,
  galaxy,
  planet,
  continent,
  city,
  village,
  town;

  String get title => switch (this) {
    _WorldsSection.universe => 'Universe',
    _WorldsSection.galaxy => 'Galaxy',
    _WorldsSection.planet => 'Planet',
    _WorldsSection.continent => 'Continent',
    _WorldsSection.city => 'City',
    _WorldsSection.village => 'Village',
    _WorldsSection.town => 'Town',
  };

  String get subtitle => switch (this) {
    _WorldsSection.universe => 'One universe',
    _WorldsSection.galaxy => 'One galaxy',
    _WorldsSection.planet => 'One planet',
    _WorldsSection.continent => 'One continent',
    _WorldsSection.city => 'Where scenes happen in a city',
    _WorldsSection.village => 'Where scenes happen in a village',
    _WorldsSection.town => 'Where scenes happen in a town',
  };

  IconData get icon => switch (this) {
    _WorldsSection.universe => Icons.public_rounded,
    _WorldsSection.galaxy => Icons.auto_awesome_rounded,
    _WorldsSection.planet => Icons.language_rounded,
    _WorldsSection.continent => Icons.map_rounded,
    _WorldsSection.city => Icons.location_city_rounded,
    _WorldsSection.village => Icons.cottage_rounded,
    _WorldsSection.town => Icons.store_rounded,
  };

  world_model.WorldTier get tier => switch (this) {
    _WorldsSection.universe => world_model.WorldTier.universe,
    _WorldsSection.galaxy => world_model.WorldTier.galaxy,
    _WorldsSection.planet => world_model.WorldTier.planet,
    _WorldsSection.continent => world_model.WorldTier.continent,
    _WorldsSection.city ||
    _WorldsSection.village ||
    _WorldsSection.town => world_model.WorldTier.settlement,
  };

  /// Settlement kind for this section, null for non-settlement tiers.
  String? get settlementKind => switch (this) {
    _WorldsSection.city => 'city',
    _WorldsSection.village => 'village',
    _WorldsSection.town => 'town',
    _ => null,
  };

  /// The section a world of [tier] belongs to, or null for Stage,
  /// District, and Landmark, which have no section in this preview.
  static _WorldsSection? forWorld(world_model.World world) {
    if (world.tier == world_model.WorldTier.settlement) {
      return switch (world.settlementKind) {
        'city' => _WorldsSection.city,
        'village' => _WorldsSection.village,
        'town' => _WorldsSection.town,
        // Unsorted settlements belong to no single section; the
        // section filter below handles them separately.
        _ => null,
      };
    }
    for (final section in _WorldsSection.values) {
      if (section.tier == world.tier) return section;
    }
    return null;
  }
}

/// Worlds of [section] from [all], sorted by name. Unsorted settlement
/// worlds appear in every settlement section; every other world
/// appears in exactly its own section.
List<world_model.World> _sectionWorlds(
  _WorldsSection section,
  List<world_model.World> all,
) {
  final worlds = <world_model.World>[];
  for (final world in all) {
    if (world.tier != section.tier) continue;
    if (section.settlementKind != null) {
      final kind = world.settlementKind;
      if (kind != null && kind != section.settlementKind) continue;
    }
    worlds.add(world);
  }
  worlds.sort((a, b) => a.name.compareTo(b.name));
  return worlds;
}

/// The tier section below [section], or null where there is no
/// next preview section: Town is the last preview tier, and City,
/// Village, and Town share one stored tier, so a settlement world
/// has no next preview section (its next stored tier, District,
/// has no section here, and its worlds must never be created
/// unseen). A Continent child starts at City; the dialog lets the
/// user switch it to Village or Town before creating.
_WorldsSection? _childSection(_WorldsSection section) {
  if (section.settlementKind != null) return null;
  if (section == _WorldsSection.continent) return _WorldsSection.city;
  final index = _WorldsSection.values.indexOf(section);
  if (index < 0 || index + 1 >= _WorldsSection.values.length) return null;
  return _WorldsSection.values[index + 1];
}

/// One tier section: label always visible, body folds away. Closed
/// by default; Jump to opens it and scrolls to it. Worlds are grouped
/// by their parent world's name, so the nest reads inside the section
/// without duplicating a world across sections.
class _TierSection extends StatelessWidget {
  final _WorldsSection section;
  final bool open;
  final VoidCallback onHeaderTap;
  final List<world_model.World> worlds;
  final List<world_model.World> allWorlds;
  final String? selectedWorldId;
  final ValueChanged<world_model.World> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<world_model.World> onAddChild;
  final ValueChanged<world_model.World> onEdit;
  final ValueChanged<world_model.World> onDelete;

  const _TierSection({
    super.key,
    required this.section,
    required this.open,
    required this.onHeaderTap,
    required this.worlds,
    required this.allWorlds,
    required this.selectedWorldId,
    required this.onSelect,
    required this.onAdd,
    required this.onAddChild,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.porchAmberOf(context);
    final groups = _groupByParent(worlds, allWorlds);
    final childSection = _childSection(section);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        border: Border.all(color: AppColors.borderSoftOf(context)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onHeaderTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Icon(section.icon, size: 24, color: accent),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          section.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    open
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    color: accent,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (worlds.isEmpty)
                    Text(
                      'No ${section.title.toLowerCase()} yet — tap + '
                      'to name your first one.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  for (final group in groups.entries) ...[
                    if (groups.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Text(
                          'Under ${group.key}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    for (final world in group.value)
                      _WorldRow(
                        world: world,
                        selected: world.id == selectedWorldId,
                        showAddChild: childSection != null,
                        onSelect: () => onSelect(world),
                        onAddChild: () => onAddChild(world),
                        onEdit: () => onEdit(world),
                        onDelete: () => onDelete(world),
                      ),
                  ],
                  const SizedBox(height: 12),
                  AliceButton(
                    label: '+ add ${section.title.toLowerCase()}',
                    ghost: true,
                    small: true,
                    icon: Icons.add_rounded,
                    onPressed: onAdd,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Worlds grouped by parent name, groups and worlds sorted by name.
/// A world whose parent is missing from the store groups under
/// "Top level", never disappears.
Map<String, List<world_model.World>> _groupByParent(
  List<world_model.World> worlds,
  List<world_model.World> all,
) {
  final byId = {for (final w in all) w.id: w};
  final groups = <String, List<world_model.World>>{};
  for (final world in worlds) {
    final parentId = world.parentWorldId;
    final parentName = parentId == null || parentId.isEmpty
        ? 'Top level'
        : (byId[parentId]?.name ?? 'Top level');
    groups.putIfAbsent(parentName, () => []).add(world);
  }
  final sorted = <String, List<world_model.World>>{};
  for (final key in groups.keys.toList()..sort()) {
    final group = groups[key]!..sort((a, b) => a.name.compareTo(b.name));
    sorted[key] = group;
  }
  return sorted;
}

/// One world row: name, first description line, and its controls.
/// The row itself selects the world for the Stage toolbar; + adds a
/// child at the next tier down; edit and delete act on this world.
/// A world with no settlement kind is labelled unsorted in its row.
class _WorldRow extends StatelessWidget {
  final world_model.World world;
  final bool selected;
  final bool showAddChild;
  final VoidCallback onSelect;
  final VoidCallback onAddChild;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorldRow({
    required this.world,
    required this.selected,
    required this.showAddChild,
    required this.onSelect,
    required this.onAddChild,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.porchAmberOf(context);
    final unsorted =
        world.tier == world_model.WorldTier.settlement &&
        (world.settlementKind == null || world.settlementKind!.isEmpty);
    final description = world.description.trim().split('\n').first;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: selected ? accent : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      world.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (unsorted) ...[
                    const SizedBox(width: 8),
                    AliceChip(label: 'Unsorted', color: accent),
                  ],
                ],
              ),
              if (description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (showAddChild)
                      AliceButton(
                        label: '+ child',
                        ghost: true,
                        small: true,
                        icon: Icons.add_rounded,
                        onPressed: onAddChild,
                      ),
                    AliceButton(
                      label: 'edit',
                      ghost: true,
                      small: true,
                      icon: Icons.edit_rounded,
                      onPressed: onEdit,
                    ),
                    AliceDangerButton(
                      label: 'delete',
                      icon: Icons.delete_rounded,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
