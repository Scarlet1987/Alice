// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 Model selection boxes (combined preview v9): narration /
// perspective / foreshortening lists, codec choice, preview panes.
// Split from alice_v9_models.dart to keep every file under 500 lines.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/alice/v9/alice_v9_state.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

class ListBox extends StatelessWidget {
  final String title;
  final String label;
  final List<String> options;
  final List<String>? labels;
  final String selected;
  final ValueChanged<String> onSelect;
  final String? preview;

  const ListBox({
    super.key,
    required this.title,
    required this.label,
    required this.options,
    this.labels,
    required this.selected,
    required this.onSelect,
    this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return V9Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          V9Heading(title),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          for (var i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListOption(
                label: labels == null ? options[i] : labels![i],
                selected: selected == options[i],
                onTap: () => onSelect(options[i]),
              ),
            ),
          if (preview != null) V9Muted(preview!),
        ],
      ),
    );
  }
}

class ListOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ListOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.alicePale
              : AppColors.pureWhite.withValues(alpha: 0.92),
          border: Border.all(
            color: selected
                ? AppColors.aliceGreen
                : AppColors.alicePale,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${selected ? '▸ ' : ''}$label',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.pureBlack,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class CodecBox extends StatelessWidget {
  final AliceV9State state;

  const CodecBox({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('codec choices', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: state.codec,
          items: const [
            DropdownMenuItem(
              value: 'vlc',
              child: Text('VLC codec — recommended'),
            ),
            DropdownMenuItem(
              value: 'built',
              child: Text('Alice Built in'),
            ),
            DropdownMenuItem(
              value: 'own',
              child: Text('Bring your own'),
            ),
          ],
          onChanged: (v) {
            if (v != null) state.setCodec(v);
          },
          decoration: const InputDecoration(
            filled: true,
            fillColor: AppColors.alicePale,
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        V9Muted(state.codecNote),
      ],
    );
  }
}

class PreviewPane extends StatelessWidget {
  final String title;
  final String body;
  final bool large;

  const PreviewPane({
    super.key,
    required this.title,
    required this.body,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return V9Card(
      child: SizedBox(
        height: large ? 220 : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            V9Heading(title),
            const SizedBox(height: 12),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
