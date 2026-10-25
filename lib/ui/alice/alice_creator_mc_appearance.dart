// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Character Creator: the "What the world sees" section — head,
// face & weathering, overall impression, body measurements with an
// inches/cm toggle, and genital selection.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/alice/alice_creator_draft.dart';
import 'package:front_porch_ai/ui/alice/alice_creator_fields.dart';
import 'package:front_porch_ai/ui/alice/alice_widgets.dart';

/// "What the world sees": appearance, head to toe.
class McAppearanceSection extends StatelessWidget {
  final AliceCreatorDraft draft;

  const McAppearanceSection({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AliceAreaLabel('Head'),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoUp = constraints.maxWidth > 420;
            final fields = [
              AliceTextField(
                label: 'Hair color',
                controller: draft.hairColor,
                hint: 'e.g. copper, gone half to grey',
              ),
              AliceTextField(
                label: 'Eye color',
                controller: draft.eyeColor,
                hint: 'e.g. grey-green',
              ),
              AliceTextField(
                label: 'Lip color',
                controller: draft.lipColor,
                hint: 'e.g. pale rose, wind-chapped',
              ),
            ];
            if (!twoUp) {
              return Column(
                children: [
                  for (final f in fields) ...[f, const SizedBox(height: 10)],
                ],
              );
            }
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final f in fields)
                  SizedBox(width: (constraints.maxWidth - 20) / 3, child: f),
              ],
            );
          },
        ),
        const AliceAreaLabel('Face & weathering'),
        AliceTextArea(
          label: 'Scars & marks',
          controller: draft.scars,
          hint: 'How weathered they look: scars, lines, wind and sun',
          minLines: 2,
          maxLines: 4,
        ),
        const AliceAreaLabel('Overall impression'),
        AliceTextArea(
          label: 'Appearance notes',
          controller: draft.appearanceNotes,
          hint: 'Anything the fields above miss',
          minLines: 2,
          maxLines: 4,
        ),
        const AliceAreaLabel('Body measurements'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AliceTextField(
                    label: 'Bust size',
                    controller: draft.bust,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AliceSegmentedControl<bool>(
                    values: const [true, false],
                    labels: const ['Inches', 'CM'],
                    selected: draft.bustInches,
                    onChanged: draft.setBustInches,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AliceTextField(
                    label: 'Hips measurement',
                    controller: draft.hips,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AliceSegmentedControl<bool>(
                    values: const [true, false],
                    labels: const ['Inches', 'CM'],
                    selected: draft.hipsInches,
                    onChanged: draft.setHipsInches,
                  ),
                ],
              ),
            ),
          ],
        ),
        const AliceAreaLabel('Genital selection'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  AliceSegmentedControl<GenitalOption>(
                    values: GenitalOption.values,
                    labels: const ['Male', 'Female'],
                    selected: draft.topGenital,
                    onChanged: draft.setTopGenital,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bottom', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  AliceSegmentedControl<GenitalOption>(
                    values: GenitalOption.values,
                    labels: const ['Male', 'Female'],
                    selected: draft.bottomGenital,
                    onChanged: draft.setBottomGenital,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
