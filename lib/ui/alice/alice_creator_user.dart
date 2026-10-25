// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice Character Creator: the You pane — the slimmest one. Real name,
// birthday, persona name, pronouns, and a short bio about the real user.
// Nothing about any character lives here. Saved to SharedPreferences.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/alice/alice_creator_draft.dart';
import 'package:front_porch_ai/ui/alice/alice_creator_fields.dart';
import 'package:front_porch_ai/ui/alice/alice_widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// The You pane: how other users see you.
class UserPane extends StatelessWidget {
  final AliceCreatorDraft draft;

  const UserPane({super.key, required this.draft});

  Future<void> _pickBirthday(BuildContext context) async {
    final now = DateTime.now();
    final initial =
        DateTime.tryParse(draft.userBirthday.text.trim()) ??
        DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Your birthday',
    );
    if (picked != null) {
      draft.userBirthday.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final words = draft.bioWordCount;
    final overLimit = words > 300;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AliceInfoWell(
          title: 'This one is you.',
          body: 'This information is how other users see you.',
        ),
        AliceSectionHead(
          title: 'How other users see you',
          subtitle:
              'Real name and birthday, persona name and pronouns, and a '
              'short bio — nothing about any character.',
          barColor: AppColors.porchAmberOf(context),
        ),
        const SizedBox(height: 12),
        AliceTextField(label: 'Real name', controller: draft.userRealName),
        const SizedBox(height: 10),
        AliceTextField(
          label: 'Birthday',
          controller: draft.userBirthday,
          hint: 'Tap to pick a date',
          readOnly: true,
          onTap: () => _pickBirthday(context),
        ),
        const SizedBox(height: 10),
        AliceTextField(
          label: 'Persona name',
          controller: draft.userPersonaName,
          hint: 'The name other users see',
        ),
        const SizedBox(height: 10),
        AliceTextField(
          label: 'Pronouns',
          controller: draft.userPronouns,
          hint: 'e.g. they/them',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'Short bio — how other users see you, in your own words',
                style: theme.textTheme.labelLarge,
              ),
            ),
            Text(
              '$words / 300 words',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: overLimit ? theme.colorScheme.error : theme.hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: draft.userBio,
          minLines: 4,
          maxLines: 8,
          onChanged: (_) {
            // Rebuild just the counter: nudge the draft without touching
            // any other field.
            draft.touch();
          },
          decoration: const InputDecoration(
            hintText: 'A few lines about the real you — up to 300 words.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        AliceButton(
          label: 'Save persona',
          onPressed: () async {
            final err = await draft.saveUserPersona();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(err ?? 'Persona saved.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          block: true,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
