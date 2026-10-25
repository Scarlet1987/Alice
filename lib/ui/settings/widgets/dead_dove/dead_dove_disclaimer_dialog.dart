// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Front Porch AI is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Front Porch AI. If not, see <https://www.gnu.org/licenses/>.

// Dead Dove selection dialog: the disclaimer plus loading the user's own
// text and image models by file location. Shown when the user picks the
// Dead Dove zone.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/porch_design.dart';
import 'package:front_porch_ai/ui/widgets/warm_dialog.dart';

/// Shows the Dead Dove disclaimer + own-model loaders. Returns true when
/// the user confirms the zone change.
Future<bool> showDeadDoveDisclaimer(BuildContext context) async {
  var textLocation = '';
  var imageLocation = '';
  final confirmed = await showWarmDialog<bool>(
    context,
    title: 'You selected Dead Dove',
    icon: Icons.warning_amber_outlined,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Disclaimer. ',
                style: PorchType.bodySmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text:
                    'Everything Dead Dove generates is AI-generated — '
                    'characters, scenes and images alike — so there is no '
                    'legal department and no app rulebook in this zone. The '
                    'only rules in force are the boxes you tick — your '
                    'compiled red, yellow and green list is what the models '
                    'follow — plus the one floor: the legal setup that stands '
                    'under every selection. If you don\u2019t tick it, it '
                    'isn\u2019t a rule.',
                style: PorchType.bodySmall(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: PorchSpacing.md),
        Text(
          'Dead Dove also runs your own text and image models: point to '
          'where each is saved on this machine and the harness loads it '
          'as-is — 0 app-added safety rails. Your negotiated limits govern '
          'them.',
          style: PorchType.hint(context),
        ),
        const SizedBox(height: PorchSpacing.md),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Text generation model — where it\u2019s saved',
            hintText: r'e.g. C:\Models\my-story-model.gguf',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) => textLocation = v,
        ),
        const SizedBox(height: PorchSpacing.sm),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Image generation model — where it\u2019s saved',
            hintText: r'e.g. C:\Models\my-image-model.safetensors',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) => imageLocation = v,
        ),
        if (textLocation.isNotEmpty || imageLocation.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: PorchSpacing.sm),
            child: Text(
              'Model locations noted. They\u2019ll appear under "Your own '
              'models" in the checklist.',
              style: PorchType.hint(context),
            ),
          ),
      ],
    ),
    actions: [
      warmDialogCancel(context, label: 'Not now'),
      warmDialogConfirm(
        context,
        label: 'Done',
        onPressed: () => Navigator.of(context).pop(true),
      ),
    ],
  );
  return confirmed ?? false;
}
