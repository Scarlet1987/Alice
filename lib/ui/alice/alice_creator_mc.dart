// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Character Creator: the Main Character pane — the protagonist's
// whole board. Core fields up top, then the collapsible sections
// (Kardashev, gear, personality, appearance, greeting/voice, model
// features, world), then Save + Chat.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/alice/alice_creator_draft.dart';
import 'package:front_porch_ai/ui/alice/alice_creator_fields.dart';
import 'package:front_porch_ai/ui/alice/alice_creator_mc_appearance.dart';
import 'package:front_porch_ai/ui/alice/alice_creator_mc_voice.dart';
import 'package:front_porch_ai/ui/alice/alice_creator_mc_world.dart';
import 'package:front_porch_ai/ui/alice/alice_widgets.dart';
import 'package:front_porch_ai/ui/creator/sections/gear_section.dart';
import 'package:front_porch_ai/ui/creator/sections/kardashev_section.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// The Main Character pane.
class McPane extends StatelessWidget {
  final AliceCreatorDraft draft;

  const McPane({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AliceInfoWell(
          title: 'The Main Character board.',
          body:
              'The protagonist\u2019s whole board — every section below, '
              'folded until you open it. Your own persona (You tab) stays slim.',
        ),
        AliceTextField(label: 'Name', controller: draft.mcName),
        const SizedBox(height: 10),
        AliceTextField(
          label: 'Role in the story',
          controller: draft.mcRole,
          hint: 'e.g. Keeper of the Gullwatch light',
        ),
        if (draft.showAllFields) ...[
          const SizedBox(height: 10),
          AliceTextField(
            label: 'Scenario',
            controller: draft.mcScenario,
            hint: 'Where the story opens…',
          ),
        ],
        const SizedBox(height: 10),
        Text('Gender identity', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        AliceSegmentedControl<GenderIdentity>(
          values: GenderIdentity.values,
          labels: const ['Male', 'Female', 'Non-binary', 'Custom'],
          selected: draft.gender,
          onChanged: draft.setGender,
        ),
        if (draft.gender == GenderIdentity.custom) ...[
          const SizedBox(height: 8),
          AliceTextField(
            label: 'Gender identity — in your words',
            controller: draft.genderCustom,
            hint: 'Write it the way you\u2019d say it…',
          ),
        ],
        const SizedBox(height: 10),
        Text('Pronouns', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        AliceSegmentedControl<PronounSet>(
          values: PronounSet.values,
          labels: const ['He/him', 'She/her', 'They/them', 'Custom'],
          selected: draft.pronouns,
          onChanged: draft.setPronouns,
        ),
        if (draft.pronouns == PronounSet.custom) ...[
          const SizedBox(height: 8),
          AliceTextField(
            label: 'Pronouns — in your words',
            controller: draft.pronounCustom,
            hint: 'e.g. ze/zir, xe/xem, fae/faer…',
          ),
        ],
        if (draft.showAllFields)
          AliceCollapsibleSection(
            title: 'Kardashev scale',
            subtitle:
                'How much energy this world\u2019s civilization commands; '
                'it drives the whole loadout below.',
            barColor: AppColors.porchAmberOf(context),
            initiallyOpen: true,
            child: KardashevSection(
              selected: draft.kardashev,
              locked: draft.kardashevLocked,
              onSelect: draft.setKardashev,
              onUnlock: draft.unlockKardashev,
              beyondNameController: draft.beyondName,
              beyondScopeController: draft.beyondScope,
              beyondGearController: draft.beyondGear,
            ),
          ),
        if (draft.showAllFields)
          AliceCollapsibleSection(
            title: 'Gear loadout',
            subtitle:
                'What you fight with, what protects you, what you wear — '
                'checked against the Kardashev scale as you type.',
            barColor: AppColors.frostAccentOf(context),
            child: GearSection(
              kardashevType: draft.kardashev,
              offensiveController: draft.gearOffense,
              defensiveController: draft.gearDefense,
              clothingController: draft.gearClothing,
            ),
          ),
        AliceCollapsibleSection(
          title: 'Personality',
          subtitle: 'Tone, sarcasm, alignment, and the mission underneath.',
          barColor: AppColors.lustAccentOf(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AliceTextArea(
                label: 'Personality',
                controller: draft.personality,
                hint:
                    'How they talk, what they want, what they\u2019d never do',
              ),
              const SizedBox(height: 10),
              AliceTextField(
                label: 'Tone',
                controller: draft.tone,
                hint: 'e.g. dry, blunt, quietly funny',
              ),
              const SizedBox(height: 10),
              AliceSliderField(
                label: 'Sarcasm level',
                valueLabel: '${draft.sarcasm.round()} / 10',
                value: draft.sarcasm,
                onChanged: draft.setSarcasm,
                leftCaption: 'Plays it straight',
                rightCaption: 'Dripping',
              ),
              const SizedBox(height: 10),
              AliceSliderField(
                label: 'Alignment',
                valueLabel: draft.alignmentLabel,
                value: draft.alignment,
                onChanged: draft.setAlignment,
                leftCaption: 'Good',
                rightCaption: 'Evil',
              ),
              const SizedBox(height: 10),
              AliceTextField(label: 'Core mission', controller: draft.mission),
            ],
          ),
        ),
        if (draft.showAllFields)
          AliceCollapsibleSection(
            title: 'What the world sees',
            subtitle:
                'Appearance, head to toe — what the world notices and '
                'reacts to.',
            barColor: AppColors.porchHoneyOf(context),
            child: McAppearanceSection(draft: draft),
          ),
        AliceCollapsibleSection(
          title: 'Greeting, voice & dialogue',
          subtitle:
              'The first message, the voice that speaks it, and dialogue '
              'that teaches their rhythm.',
          barColor: AppColors.porchAmberOf(context),
          child: McVoiceSection(draft: draft),
        ),
        AliceCollapsibleSection(
          title: 'Model features',
          subtitle:
              'The image engine for your scenes and the voice models for '
              'your characters, on two shelves.',
          barColor: AppColors.frostAccentOf(context),
          child: McModelFeaturesSection(draft: draft),
        ),
        if (draft.showAllFields)
          AliceCollapsibleSection(
            title: 'World',
            subtitle:
                'Where they live, widest to narrowest — plus the lore book '
                'grown from your saves.',
            barColor: AppColors.journalAccentOf(context),
            child: McWorldSection(draft: draft),
          ),
        const SizedBox(height: 12),
        AlicePeekButton(
          showingAll: draft.showAllFields,
          onToggle: draft.toggleShowAllFields,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AliceButton(
                label: 'Save character card',
                onPressed: () => draft.saveMcCard(context),
              ),
            ),
            const SizedBox(width: 10),
            AliceButton(
              label: 'Chat',
              ghost: true,
              onPressed: () => draft.goToChat(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
