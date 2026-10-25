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

// Main Character board: the protagonist's whole board — every section
// folded until opened. MC / NPC / User tabs at the top; the MC pane
// holds the collapsible sections (Kardashev, gear, personality,
// appearance, greeting/voice, model features, world). The user persona
// stays slim on the User tab.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';
import 'package:front_porch_ai/ui/creator/sections/gear_section.dart';
import 'package:front_porch_ai/ui/creator/sections/kardashev_section.dart';
import 'package:front_porch_ai/ui/creator/widgets/mc_collapsible_section.dart';

/// Which board is showing.
enum McBoardTab { mc, npc, user }

/// The Main Character board page.
class McBoardPage extends StatefulWidget {
  const McBoardPage({super.key});

  @override
  State<McBoardPage> createState() => _McBoardPageState();
}

class _McBoardPageState extends State<McBoardPage> {
  McBoardTab _tab = McBoardTab.mc;
  KardashevType _kardashev = KardashevType.type1;
  bool _kardashevLocked = false;

  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _personalityCtrl = TextEditingController();
  final _toneCtrl = TextEditingController();
  final _missionCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _personalityCtrl.dispose();
    _toneCtrl.dispose();
    _missionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Character creator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(PorchSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You author the main character and yourself; the AI writes '
              'the supporting cast.',
              style: PorchType.hint(context),
            ),
            const SizedBox(height: PorchSpacing.md),
            PorchSegmentedControl<McBoardTab>(
              options: const [
                PorchSegmentOption(value: McBoardTab.mc, label: 'Main Character'),
                PorchSegmentOption(value: McBoardTab.npc, label: 'NPC'),
                PorchSegmentOption(value: McBoardTab.user, label: 'You (User)'),
              ],
              value: _tab,
              onChanged: (t) => setState(() => _tab = t),
            ),
            const SizedBox(height: PorchSpacing.md),
            switch (_tab) {
              McBoardTab.mc => _McPane(
                  nameCtrl: _nameCtrl,
                  roleCtrl: _roleCtrl,
                  personalityCtrl: _personalityCtrl,
                  toneCtrl: _toneCtrl,
                  missionCtrl: _missionCtrl,
                  kardashev: _kardashev,
                  kardashevLocked: _kardashevLocked,
                  onKardashevSelect: (t) =>
                      setState(() => _kardashev = t),
                  onKardashevUnlock: () =>
                      setState(() => _kardashevLocked = false),
                ),
              McBoardTab.npc => const _NpcPane(),
              McBoardTab.user => const _UserPane(),
            },
          ],
        ),
      ),
    );
  }
}

class _McPane extends StatelessWidget {
  const _McPane({
    required this.nameCtrl,
    required this.roleCtrl,
    required this.personalityCtrl,
    required this.toneCtrl,
    required this.missionCtrl,
    required this.kardashev,
    required this.kardashevLocked,
    required this.onKardashevSelect,
    required this.onKardashevUnlock,
  });

  final TextEditingController nameCtrl;
  final TextEditingController roleCtrl;
  final TextEditingController personalityCtrl;
  final TextEditingController toneCtrl;
  final TextEditingController missionCtrl;
  final KardashevType kardashev;
  final bool kardashevLocked;
  final ValueChanged<KardashevType> onKardashevSelect;
  final VoidCallback onKardashevUnlock;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PorchCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The Main Character board.',
                style: PorchType.body(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'The protagonist\u2019s whole board — every section below, '
                'folded until you open it. Your own persona (User tab) stays '
                'slim.',
                style: PorchType.hint(context),
              ),
              const SizedBox(height: PorchSpacing.md),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: PorchSpacing.sm),
              TextField(
                controller: roleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Role in the story',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PorchSpacing.md),
        McCollapsibleSection(
          title: 'Kardashev scale',
          subtitle:
              'How much energy this world\u2019s civilization commands; it '
              'drives the whole loadout below.',
          accent: AppColors.porchAmberOf(context),
          initiallyOpen: true,
          child: KardashevSection(
            selected: kardashev,
            locked: kardashevLocked,
            onSelect: onKardashevSelect,
            onUnlock: onKardashevUnlock,
          ),
        ),
        const SizedBox(height: PorchSpacing.md),
        McCollapsibleSection(
          title: 'Gear loadout',
          subtitle:
              'What you fight with, what protects you, what you wear — '
              'checked against the Kardashev scale as you type.',
          accent: AppColors.frostAccentOf(context),
          child: GearSection(kardashevType: kardashev),
        ),
        const SizedBox(height: PorchSpacing.md),
        McCollapsibleSection(
          title: 'Personality',
          subtitle: 'Tone, sarcasm, alignment, and the mission underneath.',
          accent: AppColors.lustAccentOf(context),
          child: Column(
            children: [
              TextField(
                controller: personalityCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Personality',
                  hintText:
                      'How they talk, what they want, what they\u2019d never do',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: PorchSpacing.sm),
              TextField(
                controller: toneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tone',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: PorchSpacing.sm),
              TextField(
                controller: missionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Core mission',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PorchSpacing.md),
        Row(
          children: [
            Expanded(
              child: PorchPrimaryButton(
                label: 'Save character card',
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NpcPane extends StatelessWidget {
  const _NpcPane();

  @override
  Widget build(BuildContext context) {
    return PorchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NPCs — supporting cast',
            style: PorchType.sectionTitle(context),
          ),
          Text(
            'The AI writes your NPCs — you just give the spark.',
            style: PorchType.hint(context),
          ),
          const SizedBox(height: PorchSpacing.md),
          Text(
            'That\u2019s the whole job here — the AI fills in appearance, '
            'personality and the rest when it drafts the card.',
            style: PorchType.bodySmall(context),
          ),
          const SizedBox(height: PorchSpacing.md),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Name this NPC…',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: PorchSpacing.sm),
          const TextField(
            decoration: InputDecoration(
              labelText: 'One-line concept',
              hintText: 'The spark; one line is plenty',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: PorchSpacing.md),
          PorchPrimaryButton(
            label: 'Draft this NPC with AI',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _UserPane extends StatelessWidget {
  const _UserPane();

  @override
  Widget build(BuildContext context) {
    return PorchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This one is you.',
            style: PorchType.body(
              context,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            'This information is how other users see you.',
            style: PorchType.hint(context),
          ),
          const SizedBox(height: PorchSpacing.md),
          Text(
            'How other users see you',
            style: PorchType.sectionTitle(context),
          ),
          Text(
            'Real name and birthday, persona name and pronouns, and a short '
            'bio — nothing about any character.',
            style: PorchType.hint(context),
          ),
          const SizedBox(height: PorchSpacing.md),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Real name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: PorchSpacing.sm),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Persona name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: PorchSpacing.sm),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Pronouns',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: PorchSpacing.sm),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Short bio (up to 300 words)',
              hintText: 'How other users see you, in your own words',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: PorchSpacing.md),
          PorchPrimaryButton(label: 'Save persona', onPressed: () {}),
        ],
      ),
    );
  }
}
