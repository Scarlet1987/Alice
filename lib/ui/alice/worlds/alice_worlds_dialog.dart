// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Worlds: new / edit world dialog. Part of alice_worlds.dart.

part of '../alice_worlds.dart';

/// New / edit world dialog, through the warm-dialog scaffold. The
/// parent list follows the section's parent tier, so a world always
/// hangs under a world one scale wider — or under nothing, top level.
class _WorldDialog extends StatefulWidget {
  final world_model.World? existing;
  final _WorldsSection initialSection;
  final world_model.World? initialParent;
  final List<world_model.World> allWorlds;

  const _WorldDialog({
    this.existing,
    required this.initialSection,
    this.initialParent,
    required this.allWorlds,
  });

  @override
  State<_WorldDialog> createState() => _WorldDialogState();
}

class _WorldDialogState extends State<_WorldDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late _WorldsSection _section;
  String? _parentId;
  bool _sectionTouched = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _descController = TextEditingController(
      text: widget.existing?.description ?? '',
    );
    _section = widget.initialSection;
    _parentId = widget.initialParent?.id ?? widget.existing?.parentWorldId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  List<world_model.World> get _parents {
    final parentTier = _section.tier.parentTier;
    if (parentTier == null) return const [];
    final parents =
        widget.allWorlds
            .where((w) => w.tier == parentTier)
            .where((w) => w.id != widget.existing?.id)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return parents;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final parents = _parents;
    return WarmDialog(
      title: isEdit ? 'Edit world' : 'New world',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<_WorldsSection>(
            initialValue: _section,
            decoration: const InputDecoration(labelText: 'Scale'),
            items: [
              for (final section in _WorldsSection.values)
                DropdownMenuItem(value: section, child: Text(section.title)),
            ],
            onChanged: (section) {
              if (section == null) return;
              setState(() {
                _section = section;
                _sectionTouched = true;
                _parentId = null;
              });
            },
          ),
          if (_section.settlementKind != null) ...[
            const SizedBox(height: 12),
            const Text('Settlement kind follows the scale you picked.'),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: parents.any((w) => w.id == _parentId)
                ? _parentId
                : null,
            decoration: const InputDecoration(labelText: 'Parent'),
            items: [
              const DropdownMenuItem(value: null, child: Text('No parent')),
              for (final parent in parents)
                DropdownMenuItem(value: parent.id, child: Text(parent.name)),
            ],
            onChanged: (id) => setState(() => _parentId = id),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
        ],
      ),
      actions: [
        warmDialogCancel(context),
        warmDialogConfirm(
          context,
          label: isEdit ? 'Save' : 'Create',
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            final world =
                widget.existing ??
                world_model.World(
                  name: name,
                  description: _descController.text.trim(),
                  lorebook: Lorebook(entries: []),
                );
            world.name = name;
            world.description = _descController.text.trim();
            // An unsorted settlement edited without touching Scale
            // keeps its tier and its null kind: the dialog's section
            // is only a starting point for it, not a silent re-sort.
            if (widget.existing == null || _sectionTouched) {
              world.tier = _section.tier;
              world.settlementKind = _section.settlementKind;
            }
            world.parentWorldId = _parentId;
            Navigator.of(context).pop(world);
          },
        ),
      ],
    );
  }
}
