// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';
import 'package:front_porch_ai/ui/widgets/warm_dialog.dart';

/// One plain-English glossary entry.
class GlossaryEntry {
  const GlossaryEntry({
    required this.term,
    required this.short,
    required this.definition,
  });

  final String term;
  final String short;
  final String definition;
}

/// The in-app glossary: MC, NPC, User, and the other core terms, in plain
/// English. Shown as helper chips wherever the terms appear, plus a full
/// dialog from Settings.
class PorchGlossary {
  PorchGlossary._();

  static const List<GlossaryEntry> entries = [
    GlossaryEntry(
      term: 'MC',
      short: 'Main Character',
      definition:
          'The primary character you chat with. A character card describes '
          'the MC: their personality, appearance, voice and story. That is '
          'them — not you.',
    ),
    GlossaryEntry(
      term: 'NPC',
      short: 'Non-Playable Character',
      definition:
          'Supporting cast members in group chats. NPCs talk and act on '
          'their own, but the story revolves around you and the MC.',
    ),
    GlossaryEntry(
      term: 'User',
      short: 'You, the account holder',
      definition:
          'The human holding the device. Your persona tells the AI who it '
          'is talking to. Your details are kept separate and are never '
          'mixed into a character\u2019s data.',
    ),
    GlossaryEntry(
      term: 'Persona',
      short: 'Your stand-in',
      definition:
          'The name, description and picture the AI sees for you in chat. '
          'Edit it any time — the MC still meets whoever you decide to be.',
    ),
    GlossaryEntry(
      term: 'Lorebook',
      short: 'World facts',
      definition:
          'Reference entries the AI consults to stay consistent: places, '
          'history, and the rules of the world.',
    ),
    GlossaryEntry(
      term: 'Greeting',
      short: 'First message',
      definition:
          'The message a character opens a new chat with. Alternate '
          'greetings give each new chat a different start.',
    ),
  ];

  static GlossaryEntry? find(String term) {
    for (final e in entries) {
      if (e.term.toLowerCase() == term.toLowerCase()) return e;
    }
    return null;
  }
}

/// Opens the full glossary dialog (routes through [showWarmDialog]).
Future<void> showGlossaryDialog(BuildContext context) {
  return showWarmDialog<void>(
    context,
    title: 'What do these words mean?',
    icon: Icons.menu_book_outlined,
    width: 420,
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in PorchGlossary.entries) ...[
              _GlossaryRow(entry: entry),
              const SizedBox(height: PorchSpacing.md),
            ],
          ],
        ),
      ),
    ),
    actions: [warmDialogCancel(context, label: 'Close')],
  );
}

/// Tappable term chip. Shows the term; tapping opens its definition.
class GlossaryChip extends StatelessWidget {
  const GlossaryChip({super.key, required this.term});

  final String term;

  @override
  Widget build(BuildContext context) {
    final entry = PorchGlossary.find(term);
    if (entry == null) return const SizedBox.shrink();
    return InkWell(
      onTap: () => _showTerm(context, entry),
      borderRadius: BorderRadius.circular(PorchRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PorchSpacing.sm,
          vertical: PorchSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.porchAmberOf(context).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(PorchRadius.pill),
          border: Border.all(
            color: AppColors.porchAmberOf(context).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.term,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: AppColors.porchAmberOf(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: PorchSpacing.xs),
            Icon(
              Icons.help_outline,
              size: 13,
              color: AppColors.porchAmberOf(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline text button linking to the full glossary.
class GlossaryLink extends StatelessWidget {
  const GlossaryLink({super.key, this.label = 'What do MC, NPC and User mean?'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showGlossaryDialog(context),
      icon: Icon(
        Icons.menu_book_outlined,
        size: 16,
        color: AppColors.porchAmberOf(context),
      ),
      label: Text(
        label,
        style: TextStyle(color: AppColors.porchAmberOf(context), fontSize: 13),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: PorchSpacing.sm,
          vertical: PorchSpacing.xs,
        ),
      ),
    );
  }
}

Future<void> _showTerm(BuildContext context, GlossaryEntry entry) {
  return showWarmDialog<void>(
    context,
    title: '${entry.term} — ${entry.short}',
    icon: Icons.menu_book_outlined,
    content: WarmDialogText(entry.definition),
    actions: [warmDialogCancel(context, label: 'Close')],
  );
}

class _GlossaryRow extends StatelessWidget {
  const _GlossaryRow({required this.entry});

  final GlossaryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: PorchSpacing.sm,
            vertical: PorchSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.sunkenSurfaceOf(context),
            borderRadius: BorderRadius.circular(PorchRadius.sm),
          ),
          child: Text(
            entry.term,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: AppColors.porchAmberOf(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: PorchSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.short,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(entry.definition, style: PorchType.hint(context)),
            ],
          ),
        ),
      ],
    );
  }
}
