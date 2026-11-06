// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 Creator: personality and class alignment (combined preview
// v9), including the sarcasm percent dropdown. Split from
// alice_v9_creator.dart to keep every file under 500 lines.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/alice/v9/alice_v9_state.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

class PersonalityCard extends StatelessWidget {
  final AliceV9State state;

  const PersonalityCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return V9Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const V9Heading('personality and class alignment'),
          const SizedBox(height: 12),
          _AxisDropdown(
            label: 'ethical axis',
            value: state.ethicalAxis,
            options: const ['lawful', 'neutral', 'chaotic'],
            onChanged: (v) => state.setEthicalAxis(v),
          ),
          const SizedBox(height: 12),
          _AxisDropdown(
            label: 'moral axis',
            value: state.moralAxis,
            options: const ['good', 'neutral', 'evil'],
            onChanged: (v) => state.setMoralAxis(v),
          ),
          const SizedBox(height: 12),
          Text(
            'personality mannerisms — type it in',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          TextField(
            controller: state.mcPersonality,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText:
                  'Type it in your own words, one habit per line. For example: fidgets with sleeves when thinking.',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.alicePale,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'how they talk (tone) — type it in',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          TextField(
            controller: state.mcTone,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText:
                  'Type how they talk, in your own words. For example: cocky and sarcastic, but all lady.',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.alicePale,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'sarcasm level',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<int>(
            initialValue: state.sarcasmPercent,
            items: [
              for (var percent = 0; percent <= 100; percent += 10)
                DropdownMenuItem(
                  value: percent,
                  child: Text('$percent%'),
                ),
            ],
            onChanged: (v) {
              if (v != null) state.setSarcasmPercent(v);
            },
            decoration: const InputDecoration(
              filled: true,
              fillColor: AppColors.alicePale,
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          const V9Heading('class choice'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final choice in [
                'royalty',
                'highclass',
                'skilled labor',
                'unskilled labor',
              ])
                _ClassButton(
                  label: choice,
                  selected: state.classChoice == choice,
                  onTap: () => state.setClassChoice(choice),
                ),
            ],
          ),
          const SizedBox(height: 16),
          V9Muted(state.characterPreview),
        ],
      ),
    );
  }
}

class _AxisDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _AxisDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: [
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          decoration: const InputDecoration(
            filled: true,
            fillColor: AppColors.alicePale,
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _ClassButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ClassButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.pureWhite : AppColors.aliceGreen,
          border: Border.all(
            color: AppColors.aliceGreen,
            width: selected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.aliceGreen : AppColors.pureWhite,
            fontFamily: 'Georgia',
          ),
        ),
      ),
    );
  }
}
