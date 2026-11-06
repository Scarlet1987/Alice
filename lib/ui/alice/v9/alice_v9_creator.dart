// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 Character creator (combined preview v9): tailor's
// measurements on top (flat, file order, sliders, cm/in both green),
// then MC and NPC side by side — no You base user data box, that is
// covered in User profile — then personality and class alignment
// stacked, with class choice inside it. Sarcasm level is a percent
// dropdown, 0% to 100% in 10% steps, default 0% — never a text input.
// The character preview updates as you type and pick, including a
// typed custom pronoun. Save writes a real character card to the
// library; the draft autosaves to storage as you work.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/services/character_repository.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_identity.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_state.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_creator_measurements.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_creator_personality.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

class AliceV9CreatorPage extends StatelessWidget {
  final AliceV9State state;

  const AliceV9CreatorPage({super.key, required this.state});

  Future<void> _saveMc(BuildContext context) async {
    if (state.mcName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your main character a name first.')),
      );
      return;
    }
    await state.saveCreatorDraft();
    await Provider.of<CharacterRepository>(
      context,
      listen: false,
    ).addCharacter(state.buildMcCard());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Character card saved for "${state.mcName.text.trim()}".'),
        ),
      );
    }
  }

  Future<void> _saveNpc(BuildContext context) async {
    if (state.npcName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your NPC a name first.')),
      );
      return;
    }
    await state.saveCreatorDraft();
    await Provider.of<CharacterRepository>(
      context,
      listen: false,
    ).addCharacter(state.buildNpcCard());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('NPC card saved for "${state.npcName.text.trim()}".'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              V9Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const V9Heading('physical and class attributes selection'),
                    const SizedBox(height: 16),
                    MeasurementsCard(state: state),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final mc = _IdentityCard(
                          title: 'name and gender (MC)',
                          nameController: state.mcName,
                          nameHint: 'Main character name',
                          gender: state.mcGender,
                          pronouns: state.mcPronouns,
                          onGenderPick: (pick) =>
                              state.setCreatorIdentityPick(
                                state.mcGender,
                                pick,
                              ),
                          onGenderCustom: (text) =>
                              state.setCreatorIdentityCustom(
                                state.mcGender,
                                text,
                              ),
                          onPronounsPick: (pick) =>
                              state.setCreatorIdentityPick(
                                state.mcPronouns,
                                pick,
                              ),
                          onPronounsCustom: (text) =>
                              state.setCreatorIdentityCustom(
                                state.mcPronouns,
                                text,
                              ),
                          onSave: () => _saveMc(context),
                          saveLabel: 'Save main character',
                          creatorSaved: state.creatorSaved,
                        );
                        final npc = _IdentityCard(
                          title: 'name and gender (NPC)',
                          nameController: state.npcName,
                          nameHint: 'NPC name',
                          gender: state.npcGender,
                          pronouns: state.npcPronouns,
                          onGenderPick: (pick) =>
                              state.setCreatorIdentityPick(
                                state.npcGender,
                                pick,
                              ),
                          onGenderCustom: (text) =>
                              state.setCreatorIdentityCustom(
                                state.npcGender,
                                text,
                              ),
                          onPronounsPick: (pick) =>
                              state.setCreatorIdentityPick(
                                state.npcPronouns,
                                pick,
                              ),
                          onPronounsCustom: (text) =>
                              state.setCreatorIdentityCustom(
                                state.npcPronouns,
                                text,
                              ),
                          onSave: () => _saveNpc(context),
                          saveLabel: 'Save NPC',
                          creatorSaved: state.creatorSaved,
                          extra: _NpcExtras(state: state),
                        );
                        if (constraints.maxWidth < 700) {
                          return Column(
                            children: [
                              mc,
                              const SizedBox(height: 16),
                              npc,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: mc),
                            const SizedBox(width: 16),
                            Expanded(child: npc),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    PersonalityCard(state: state),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final String title;
  final TextEditingController nameController;
  final String nameHint;
  final V9Identity gender;
  final V9Identity pronouns;
  final ValueChanged<String> onGenderPick;
  final ValueChanged<String> onGenderCustom;
  final ValueChanged<String> onPronounsPick;
  final ValueChanged<String> onPronounsCustom;
  final VoidCallback onSave;
  final String saveLabel;
  final bool creatorSaved;
  final Widget? extra;

  const _IdentityCard({
    required this.title,
    required this.nameController,
    required this.nameHint,
    required this.gender,
    required this.pronouns,
    required this.onGenderPick,
    required this.onGenderCustom,
    required this.onPronounsPick,
    required this.onPronounsCustom,
    required this.onSave,
    required this.saveLabel,
    required this.creatorSaved,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return V9Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          V9Heading(title),
          const SizedBox(height: 12),
          Text('Name', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: nameHint,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.alicePale,
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          V9IdentityRow(
            label: 'gender identity',
            options: kV9GenderOptions,
            customHint: 'Type your gender identity…',
            value: gender,
            onPick: onGenderPick,
            onCustomChanged: onGenderCustom,
            saved: creatorSaved,
          ),
          const SizedBox(height: 12),
          V9IdentityRow(
            label: 'pronouns',
            options: kV9PronounOptions,
            customHint: 'Type your pronouns, e.g. xe/xem…',
            value: pronouns,
            onPick: onPronounsPick,
            onCustomChanged: onPronounsCustom,
            saved: creatorSaved,
          ),
          if (extra != null) ...[const SizedBox(height: 12), extra!],
          const SizedBox(height: 16),
          V9Button(label: saveLabel, onPressed: onSave),
        ],
      ),
    );
  }
}

class _NpcExtras extends StatelessWidget {
  final AliceV9State state;

  const _NpcExtras({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Role', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: state.npcRole,
          items: const [
            'Ally',
            'Villain',
            'Merchant',
            'Mentor',
            'Rival',
            'Comic relief',
            'Love interest',
            'Wildcard',
          ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) {
            if (v == null) return;
            state.setNpcRole(v);
          },
          decoration: const InputDecoration(
            filled: true,
            fillColor: AppColors.alicePale,
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        Text('One-line concept', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        TextField(
          controller: state.npcConcept,
          decoration: const InputDecoration(
            hintText: 'The spark the AI writes from…',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.alicePale,
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Relationship to MC',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        TextField(
          controller: state.npcRelationship,
          decoration: const InputDecoration(
            hintText: 'e.g. old friend, rival, mentor…',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.alicePale,
            isDense: true,
          ),
        ),
      ],
    );
  }
}

