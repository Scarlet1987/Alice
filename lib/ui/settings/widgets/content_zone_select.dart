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

// The content-zone change flow, shared by the Settings content-zone card
// and the Alice edition Settings screen: adult zones require 18+
// verification first (downgrade is always free), Dead Dove shows the
// disclaimer + own-model loader before the switch lands.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/services/storage/storage.dart';
import 'package:front_porch_ai/ui/settings/widgets/dead_dove/dead_dove_disclaimer_dialog.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';
import 'package:front_porch_ai/ui/widgets/warm_dialog.dart';

/// Runs the zone-change flow. Returns true when the zone actually changed.
Future<bool> selectContentZone(
  BuildContext context,
  UiSettings uiSettings,
  ContentZone zone,
) async {
  if (zone == uiSettings.contentZone) return false;
  // Adult zones require 18+ verification; downgrade is always free.
  if (zone.requiresAdult && !uiSettings.adultVerified) {
    final verified = await _verifyAdult(context);
    if (!verified) return false;
    await uiSettings.setAdultVerified(true);
  }
  // Dead Dove opens the disclaimer + own-model loader first.
  if (zone == ContentZone.deadDove) {
    final confirmed = await showDeadDoveDisclaimer(context);
    if (!confirmed) return false;
  }
  await uiSettings.setContentZone(zone);
  return true;
}

/// Simple 18+ verification: the user enters their birthdate; 18+ passes.
Future<bool> _verifyAdult(BuildContext context) async {
  DateTime? birthdate;
  final confirmed = await showWarmDialog<bool>(
    context,
    title: '18+ verification',
    icon: Icons.verified_user_outlined,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The NSFW and Dead Dove zones allow adult content. '
          'Please confirm you are 18 or older.',
          style: PorchType.body(context),
        ),
        const SizedBox(height: PorchSpacing.md),
        _BirthdateField(onChanged: (d) => birthdate = d),
      ],
    ),
    actions: [
      warmDialogCancel(context),
      warmDialogConfirm(
        context,
        label: 'Verify',
        onPressed: () {
          final d = birthdate;
          final adult =
              d != null && DateTime.now().difference(d).inDays >= 18 * 365;
          Navigator.of(context).pop(adult);
        },
      ),
    ],
  );
  return confirmed ?? false;
}

class _BirthdateField extends StatefulWidget {
  const _BirthdateField({required this.onChanged});

  final ValueChanged<DateTime?> onChanged;

  @override
  State<_BirthdateField> createState() => _BirthdateFieldState();
}

class _BirthdateFieldState extends State<_BirthdateField> {
  DateTime? _date;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(now.year - 20, now.month, now.day),
          firstDate: DateTime(now.year - 120),
          lastDate: now,
        );
        if (picked != null) {
          setState(() => _date = picked);
          widget.onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Birthdate',
          border: OutlineInputBorder(),
        ),
        child: Text(
          _date == null
              ? 'Tap to select'
              : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-'
                    '${_date!.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
