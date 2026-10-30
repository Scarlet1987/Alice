// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Front Porch AI is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Front Porch AI. If not, see <https://www.gnu.org/licenses/>.

/// Creator notes data, extracted from alice_creator_notes.dart so that
/// board file stays under the 500-line god-file bar. No wording change:
/// the Kardashev rubric and the Gear-by-limb sections are moved whole.

/// Layman's rubric, wording exactly as in the approved preview.
const kardashevRubric = <String, String>{
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

class NotesSection {
  const NotesSection({
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

const notesSections = [
  NotesSection(
    title: 'Accessories',
    fields: [
      'Earrings and piercings',
      'Necklace',
      'Amulet',
      'Collar',
      'Thigh accessories',
    ],
  ),
  NotesSection(title: 'Armor', fields: ['Chest', 'Torso', 'Legs', 'Thigh']),
  NotesSection(
    title: 'Weapons',
    fields: ['Long range', 'Close range', 'Intimate range'],
  ),
  NotesSection(
    title: 'Clothing',
    fields: ['Intimates', 'Style of intimates'],
    subheading: 'Outer wear',
    subfields: ['Head', 'Torso', 'Chest', 'Legs', 'Feet'],
  ),
  NotesSection(
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

