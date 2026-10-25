// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Character Creator: small labeled field widgets shared by the
// MC / NPC / You panes. Labels stay plain-English; styling comes from
// the app theme, never hardcoded colors.

import 'package:flutter/material.dart';

/// A labeled single-line text field.
class AliceTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;

  const AliceTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

/// A labeled multi-line text area.
class AliceTextArea extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final int minLines;
  final int maxLines;

  const AliceTextArea({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.minLines = 3,
    this.maxLines = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

/// A labeled slider row with end labels and a live value chip.
class AliceSliderField extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String leftCaption;
  final String rightCaption;

  const AliceSliderField({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 10,
    this.divisions = 10,
    required this.leftCaption,
    required this.rightCaption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                valueLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftCaption, style: theme.textTheme.bodySmall),
            Text(rightCaption, style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

/// A tinted info well: bold lead-in, then plain-English explanation.
class AliceInfoWell extends StatelessWidget {
  final String title;
  final String body;

  const AliceInfoWell({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: ' $body', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Small caps area label inside a section ("Head", "Body measurements").
class AliceAreaLabel extends StatelessWidget {
  final String text;

  const AliceAreaLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// "Show every field anyway" — reveals the Balanced+ gated fields.
class AlicePeekButton extends StatelessWidget {
  final bool showingAll;
  final VoidCallback onToggle;

  const AlicePeekButton({
    super.key,
    required this.showingAll,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onToggle,
        child: Text(
          showingAll
              ? 'Hide the extra fields — back to the simple view'
              : 'Show every field anyway — detail level is a default, not a cage',
        ),
      ),
    );
  }
}
