// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Creator board built exactly from Elaina's notes structure, not
// from the old template: Jump to, Kardashev scale selection, then
// Gear by limb as the master parent with Accessories, Armor,
// Weapons, Clothing, and Items as its children. Every gear field
// is + / − plus a user-text input. The preview's "First time user"
// and "Movement vs lag" helper cards are intentionally not here:
// they explain the preview, they are not Creator data.
//
// Labels are always visible. The Gear sections and the rubric are
// collapsible references, opened by their visible label or by a
// Jump button; no required field is hidden behind a show-all gate.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/alice/alice_creator_draft.dart';
import 'package:front_porch_ai/ui/alice/alice_forest_background.dart';
import 'package:front_porch_ai/ui/alice/alice_widgets.dart';
import 'package:front_porch_ai/ui/creator/sections/kardashev_section.dart';

/// Layman's rubric, wording exactly as in the approved preview.
const _kardashevRubric = <String, String>{
  'Type 1 — Planetary':
      'Controls all the energy of one planet. Can tame weather, '
      'volcanoes, and earthquakes, and power everything from the '
      'planet itself. Can\u2019t yet harness a whole star.',
  'Type 2 — Stellar':
      'Controls all the energy of one star. Can build a Dyson swarm '
      'around its sun, settle a whole solar system, and travel easily '
      'between planets. Can\u2019t yet use other stars at scale.',
  'Type 3 — Galactic':
      'Controls all the energy of one galaxy. Can travel between '
      'stars, use billions of stars at once, and move planets. '
      'Can\u2019t yet leave its galaxy or control another one.',
  'All skills are earned':
      'No type hands a character everything at once. No matter how '
      'advanced the civilization is, skills are earned in the story.',
  'Type 4 — Universal':
      'Controls all the energy of one universe. Can cross the '
      'universe, bend space and time, and use whole galaxies like '
      'tools. Can\u2019t yet leave its universe.',
  'Type 5 — Multiversal':
      'Controls energy across many universes. Can step between '
      'realities and use more than one universe at once. Its only '
      'real limit is what you decide it is.',
  'Beyond — You define it':
      'No preset power level. You name what this civilization '
      'commands, and the gear check measures against your own '
      'description instead of a fixed scale.',
};

class _NotesSection {
  const _NotesSection({
    required this.title,
    required this.fields,
    this.subheading,
    this.subfields = const [],
  });

  final String title;
  final List<String> fields;
  final String? subheading;
  final List<String> subfields;
}

const _notesSections = [
  _NotesSection(
    title: 'Accessories',
    fields: [
      'Earrings and piercings',
      'Necklace',
      'Amulet',
      'Collar',
      'Thigh accessories',
    ],
  ),
  _NotesSection(title: 'Armor', fields: ['Chest', 'Torso', 'Legs', 'Thigh']),
  _NotesSection(
    title: 'Weapons',
    fields: ['Long range', 'Close range', 'Intimate range'],
  ),
  _NotesSection(
    title: 'Clothing',
    fields: ['Intimates', 'Style of intimates'],
    subheading: 'Outer wear',
    subfields: ['Head', 'Torso', 'Chest', 'Legs', 'Feet'],
  ),
  _NotesSection(
    title: 'Items',
    fields: [],
    subheading: 'Consumables',
    subfields: [
      'Health potion',
      'Mana potion',
      'Consumable other — food, water, etc.',
    ],
  ),
];

/// The notes-structure board for the Main Character tab.
class CreatorNotesBoard extends StatefulWidget {
  final AliceCreatorDraft draft;

  const CreatorNotesBoard({super.key, required this.draft});

  @override
  State<CreatorNotesBoard> createState() => _CreatorNotesBoardState();
}

class _CreatorNotesBoardState extends State<CreatorNotesBoard> {
  final Map<String, bool> _open = {};
  final Map<String, GlobalKey> _keys = {};

  GlobalKey _keyFor(String title) =>
      _keys.putIfAbsent(title, () => GlobalKey());

  void _jumpTo(String title) {
    setState(() => _open[title] = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _keyFor(title).currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, duration: Durations.short4);
      }
    });
  }

  void _showAll() {
    setState(() {
      for (final section in _notesSections) {
        _open[section.title] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _jumpCard(context),
        const SizedBox(height: 12),
        _kardashevCard(context, theme),
        const SizedBox(height: 12),
        AliceTranslucentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AliceSectionHead(
                title: 'Gear by limb',
                subtitle: 'Tap a section to open it.',
              ),
              const SizedBox(height: 8),
              for (final section in _notesSections)
                _gearSection(context, section),
            ],
          ),
        ),
      ],
    );
  }

  Widget _jumpCard(BuildContext context) {
    return AliceTranslucentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AliceSectionHead(title: 'Jump to'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final title in ['Weapons', 'Armor', 'Clothing'])
                      AliceButton(
                        label: title,
                        ghost: true,
                        small: true,
                        onPressed: () => _jumpTo(title),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in {
                      'Items': 'Items',
                      'Accessories': 'Accessories',
                      'Other items': 'Items',
                    }.entries)
                      AliceButton(
                        label: entry.key,
                        ghost: true,
                        small: true,
                        onPressed: () => _jumpTo(entry.value),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AliceButton(
            label: 'Show all',
            ghost: true,
            small: true,
            onPressed: _showAll,
          ),
        ],
      ),
    );
  }

  Widget _kardashevCard(BuildContext context, ThemeData theme) {
    final draft = widget.draft;
    const types = [
      KardashevType.type1,
      KardashevType.type2,
      KardashevType.type3,
      KardashevType.type4,
      KardashevType.type5,
      KardashevType.beyond,
    ];
    return AliceTranslucentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AliceSectionHead(title: 'Kardeshev scale selection'),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: draft,
            builder: (context, _) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final type in types) ...[
                    if (type == KardashevType.type4)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '{all skills are earned}',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ChoiceChip(
                      label: Text(type.label),
                      selected: draft.kardashev == type,
                      onSelected: draft.kardashevLocked
                          ? null
                          : (_) => draft.setKardashev(type),
                    ),
                  ],
                  if (draft.kardashevLocked) ...[
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: draft.unlockKardashev,
                      child: const Text('Unlock scale'),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Selected: ${draft.kardashev.label}'
            '${draft.kardashevLocked ? ' (locked until you unlock it)' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            title: const Text(
              'What each type means — layman\u2019s rubric',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            children: [
              for (final entry in _kardashevRubric.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: '${entry.key}: ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: entry.value),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gearSection(BuildContext context, _NotesSection section) {
    final open = _open[section.title] ?? false;
    return Container(
      key: _keyFor(section.title),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open[section.title] = !open),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      section.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    open
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final field in section.fields)
                    _gearField(section.title, field),
                  if (section.subheading != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      section.subheading!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    for (final field in section.subfields)
                      _gearField(
                        section.title,
                        field,
                        subheading: section.subheading,
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _gearField(String section, String field, {String? subheading}) {
    final key = subheading == null
        ? '$section — $field'
        : '$section — $subheading — $field';
    // Items uses the draft's Consumables key wording, which matches
    // the notes file's "Consumable other food water etc." phrasing.
    final draftKey = section == 'Items' ? 'Items — Consumables — $field' : key;
    final controllers = widget.draft.notesControllersFor(draftKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(field, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        for (var i = 0; i < controllers.length; i++)
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: 'Remove a field',
                  onPressed: () => widget.draft.removeNotesField(draftKey),
                  icon: const Icon(Icons.remove),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controllers[i],
                  decoration: const InputDecoration(
                    hintText: 'User text',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: 'Add a field',
                  onPressed: () => widget.draft.addNotesField(draftKey),
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
