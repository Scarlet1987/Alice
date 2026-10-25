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
import 'package:provider/provider.dart';

import 'package:front_porch_ai/providers/app_state.dart';
import 'package:front_porch_ai/services/user_persona_service.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';
import 'package:front_porch_ai/ui/widgets/glossary.dart';

/// "Who is who" card at the top of creation flows. Makes the User-vs-MC
/// separation unambiguous: the top half is the human's own persona (with a
/// shortcut to edit it), the bottom half is the MC being created. The two
/// data sets stay visually and descriptively distinct so it is always clear
/// which data belongs to the human and which belongs to the character.
class UserVsCharacterCard extends StatelessWidget {
  const UserVsCharacterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return PorchCard(
      padding: const EdgeInsets.all(PorchSpacing.md),
      child: Column(
        children: [
          _WhoRow(
            icon: Icons.person_outline,
            title: 'You (the User)',
            helper:
                'The human holding the device. Your persona tells the AI '
                'who it is talking to — it is never mixed into the '
                'character\u2019s data.',
            trailing: Consumer<UserPersonaService>(
              builder: (context, personas, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      personas.persona.displayLabel,
                      style: PorchType.caption(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: PorchSpacing.xs),
                  TextButton(
                    onPressed: () => Provider.of<AppState>(
                      context,
                      listen: false,
                    ).setIndex(4),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PorchSpacing.sm,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        color: AppColors.porchAmberOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PorchSpacing.sm),
            child: Divider(
              height: 1,
              color: AppColors.borderOf(context).withValues(alpha: 0.5),
            ),
          ),
          _WhoRow(
            icon: Icons.theater_comedy_outlined,
            title: 'Them (the MC)',
            helper:
                'The main character you are creating. Everything on this '
                'page describes them — not you. AI helps write your NPCs — '
                'your main character and world are yours to create.',
            trailing: const GlossaryChip(term: 'MC'),
          ),
        ],
      ),
    );
  }
}

class _WhoRow extends StatelessWidget {
  const _WhoRow({
    required this.icon,
    required this.title,
    required this.helper,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String helper;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(PorchSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.sunkenSurfaceOf(context),
            borderRadius: BorderRadius.circular(PorchRadius.md),
          ),
          child: Icon(icon, size: 20, color: AppColors.porchAmberOf(context)),
        ),
        const SizedBox(width: PorchSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(helper, style: PorchType.hint(context)),
            ],
          ),
        ),
        const SizedBox(width: PorchSpacing.sm),
        trailing,
      ],
    );
  }
}
