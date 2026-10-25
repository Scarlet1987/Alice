// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Character Creator: "Greeting, voice & dialogue" (with the
// speech-model catalog picker) and "Model features" (the Images & Voice
// shelves). The voice shelf is one shared shelf — picking in the Browse
// picker or in Model features updates the same selection.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/alice/alice_creator_draft.dart';
import 'package:front_porch_ai/ui/alice/alice_creator_fields.dart';
import 'package:front_porch_ai/ui/alice/alice_widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// A static catalog entry (not live data — the catalog is curated here).
class _CatalogModel {
  final String name;
  final String source;
  final String blurb;
  final List<String> tags;
  final bool selfHosted;

  const _CatalogModel({
    required this.name,
    required this.source,
    required this.blurb,
    required this.tags,
    required this.selfHosted,
  });
}

const _voiceModels = [
  _CatalogModel(
    name: 'NVIDIA PersonaPlex-7B',
    source: 'NVIDIA · 7B · full-duplex',
    blurb:
        'Listens and speaks at the same time — takes interruptions in stride '
        'and holds a persona and voice while it talks.',
    tags: ['~36 ms response', 'Full-duplex', 'Persona control'],
    selfHosted: true,
  ),
  _CatalogModel(
    name: 'Voila',
    source: 'Voice-language foundation model · end-to-end',
    blurb:
        'Built for real-time interaction and voice role-play, with emotional '
        'voice generation across a huge built-in voice library.',
    tags: ['~195 ms response', '1M+ voices', '10-second cloning'],
    selfHosted: true,
  ),
  _CatalogModel(
    name: 'Qwen3-TTS',
    source: 'Alibaba · 1.7B · lightweight',
    blurb:
        'Small text-to-speech with voice cloning that punches above its '
        'size — light enough for modest hardware, fluent in many languages.',
    tags: ['Light on VRAM', 'Voice cloning', 'EN · JA · ZH · ES · FR · DE'],
    selfHosted: true,
  ),
  _CatalogModel(
    name: 'DramaBox',
    source: 'Resemble AI · dramatic performance',
    blurb:
        'Built for high-emotion performance — crying, laughter, tones that '
        'shift mid-scene — with instant voice cloning.',
    tags: ['High emotional range', 'Instant cloning'],
    selfHosted: true,
  ),
  _CatalogModel(
    name: 'Cartesia Sonic 3',
    source: 'Cartesia · commercial text-to-speech',
    blurb:
        'Industry-standard commercial speech engine: ultra-low latency with '
        'hyper-realistic emotional inflection.',
    tags: ['Under 100 ms', 'Emotional inflection'],
    selfHosted: false,
  ),
  _CatalogModel(
    name: 'ElevenLabs Eleven v3',
    source: 'ElevenLabs · commercial text-to-speech',
    blurb:
        'Hyper-realistic voices with strong emotional inflection, at '
        'conversational latency.',
    tags: ['200–400 ms', 'Emotional inflection'],
    selfHosted: false,
  ),
  _CatalogModel(
    name: 'Jenova',
    source: 'Jenova · hosted voice roleplay platform',
    blurb:
        'A whole platform rather than a model: spoken campaigns with '
        'persistent memory, private across web and mobile.',
    tags: ['Spoken campaigns', 'Persistent memory'],
    selfHosted: false,
  ),
];

const _imageModels = [
  _CatalogModel(
    name: 'FLUX.1 Schnell',
    source: 'Black Forest Labs · 12B · Apache-2.0',
    blurb:
        'The fast flagship: sharp, prompt-faithful pictures in a handful of '
        'steps. Reads the scene-aware prompts the app builds.',
    tags: ['~4 steps', 'Scene-aware', 'Strong composition'],
    selfHosted: true,
  ),
  _CatalogModel(
    name: 'Stable Diffusion 3.5 Medium',
    source: 'Stability AI · 2.5B · lightweight',
    blurb:
        'A balanced mid-size model with strong prompt adherence that stays '
        'comfortable on modest hardware.',
    tags: ['Light on VRAM', 'Prompt adherence'],
    selfHosted: true,
  ),
  _CatalogModel(
    name: 'SDXL Turbo',
    source: 'Stability AI · distilled · real-time',
    blurb:
        'Drafts a picture in one to four steps — near-instant sketches of a '
        'scene while the story is still moving.',
    tags: ['1–4 steps', 'Sketch-fast'],
    selfHosted: true,
  ),
  _CatalogModel(
    name: 'Qwen-Image',
    source: 'Alibaba · 20B MMDiT',
    blurb:
        'The text specialist: renders words inside the picture — signs, '
        'letters, book covers — legibly, where most models smear them.',
    tags: ['Text in images', 'EN · ZH', 'Editing built in'],
    selfHosted: true,
  ),
];

/// One selectable model tile.
class _ModelTile extends StatelessWidget {
  final _CatalogModel model;
  final bool selected;
  final VoidCallback onTap;

  const _ModelTile({
    required this.model,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.porchAmberOf(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
          border: Border.all(
            color: selected ? accent : theme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AliceChip(
                  label: model.selfHosted ? 'Self-hosted' : 'Hosted',
                  color: model.selfHosted ? accent : null,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(model.source, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(model.blurb, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [for (final t in model.tags) AliceChip(label: t)],
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid of voice models bound to [AliceCreatorDraft.voiceModel].
class VoiceModelGrid extends StatelessWidget {
  final AliceCreatorDraft draft;

  const VoiceModelGrid({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Open-source & self-hosted',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        for (final m in _voiceModels.where((m) => m.selfHosted)) ...[
          _ModelTile(
            model: m,
            selected: draft.voiceModel == m.name,
            onTap: () => draft.setVoiceModel(m.name),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 4),
        Text(
          'Commercial & hosted',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        for (final m in _voiceModels.where((m) => !m.selfHosted)) ...[
          _ModelTile(
            model: m,
            selected: draft.voiceModel == m.name,
            onTap: () => draft.setVoiceModel(m.name),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// "Greeting, voice & dialogue" section.
class McVoiceSection extends StatefulWidget {
  final AliceCreatorDraft draft;

  const McVoiceSection({super.key, required this.draft});

  @override
  State<McVoiceSection> createState() => _McVoiceSectionState();
}

class _McVoiceSectionState extends State<McVoiceSection> {
  bool _pickerOpen = false;

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AliceTextArea(
          label: 'Greeting — the first message the character sends',
          controller: draft.greeting,
          minLines: 4,
          maxLines: 8,
        ),
        const SizedBox(height: 10),
        Text('Voice for this character', style: theme.textTheme.labelLarge),
        Text(
          'The standing answer, kept on the card.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 4),
        AliceSegmentedControl<bool>(
          values: const [true, false],
          labels: const ['Yes — give them a voice', 'No — text only'],
          selected: draft.voiceOn,
          onChanged: draft.setVoiceOn,
        ),
        const SizedBox(height: 10),
        Text('Voice speech model', style: theme.textTheme.labelLarge),
        Text(
          'Chosen with Browse — this tells the harness what speaks '
          'the character\u2019s lines.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  draft.voiceModel ?? 'No voice model picked yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: draft.voiceModel == null ? theme.hintColor : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AliceButton(
              label: _pickerOpen ? 'Close' : 'Browse',
              ghost: true,
              small: true,
              onPressed: () => setState(() => _pickerOpen = !_pickerOpen),
            ),
          ],
        ),
        if (_pickerOpen) ...[
          const SizedBox(height: 10),
          VoiceModelGrid(draft: draft),
        ],
        const SizedBox(height: 10),
        AliceTextField(
          label: 'Voice & speech',
          controller: draft.voiceSpeech,
          hint: 'e.g. low, unhurried; coastal sayings',
        ),
        const SizedBox(height: 10),
        AliceTextArea(
          label: 'Example dialogue — teaches the model their rhythm',
          controller: draft.exampleDialogue,
          hint:
              '{{user}}: Do you ever get lonely up here?\n'
              'Wren: "Lonely\u2019s a land word…"',
          minLines: 4,
          maxLines: 8,
        ),
      ],
    );
  }
}

/// "Model features" section: the Images & Voice shelves.
class McModelFeaturesSection extends StatefulWidget {
  final AliceCreatorDraft draft;

  const McModelFeaturesSection({super.key, required this.draft});

  @override
  State<McModelFeaturesSection> createState() => _McModelFeaturesSectionState();
}

class _McModelFeaturesSectionState extends State<McModelFeaturesSection> {
  bool _showImages = true;

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Two shelves: pick the image model that draws your scenes and the '
          'voice model that speaks your characters.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 8),
        AliceSegmentedControl<bool>(
          values: const [true, false],
          labels: const ['Images', 'Voice'],
          selected: _showImages,
          onChanged: (v) => setState(() => _showImages = v),
        ),
        const SizedBox(height: 10),
        if (_showImages)
          for (final m in _imageModels) ...[
            _ModelTile(
              model: m,
              selected: draft.imageModel == m.name,
              onTap: () => draft.setImageModel(m.name),
            ),
            const SizedBox(height: 8),
          ]
        else ...[
          Text(
            'One voice shelf, shared with the Browse picker in '
            '\u201cGreeting, voice & dialogue\u201d — pick in either place '
            'and both stay in step.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 8),
          VoiceModelGrid(draft: draft),
        ],
      ],
    );
  }
}
