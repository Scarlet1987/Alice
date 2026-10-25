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

// Content-zone picker: three cards (Safe Commons / NSFW / Dead Dove) with
// plain-English descriptions. Adult zones require 18+ verification first;
// downgrade freely, upgrade re-verifies. Advanced mode reveals the
// underlying policy details.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/storage/storage.dart';
import 'package:front_porch_ai/ui/settings/widgets/content_zone_select.dart';
import 'package:front_porch_ai/ui/settings/widgets/dead_dove/dead_dove_panel.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';
import 'package:front_porch_ai/ui/widgets/detail_level_control.dart';

class ContentZoneCard extends StatelessWidget {
  const ContentZoneCard({super.key});

  @override
  Widget build(BuildContext context) {
    final uiSettings = Provider.of<StorageService>(context).uiSettings;
    final zone = uiSettings.contentZone;
    final level = context.detailLevel;

    return PorchCard(
      padding: const EdgeInsets.all(PorchSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: AppColors.porchAmberOf(context),
                size: 20,
              ),
              const SizedBox(width: PorchSpacing.sm),
              Text('Content zone', style: PorchType.sectionTitle(context)),
            ],
          ),
          const SizedBox(height: PorchSpacing.xs),
          Text(
            'What you can and can\u2019t generate is determined by your zone.',
            style: PorchType.hint(context),
          ),
          const SizedBox(height: PorchSpacing.md),
          for (final z in ContentZone.values) ...[
            _ZoneTile(
              zone: z,
              selected: z == zone,
              showPolicy: level == DetailLevel.advanced,
              onSelect: () => _selectZone(context, uiSettings, z),
            ),
            const SizedBox(height: PorchSpacing.sm),
          ],
          if (zone == ContentZone.deadDove) ...[
            const SizedBox(height: PorchSpacing.sm),
            const DeadDovePanel(),
            const SizedBox(height: PorchSpacing.sm),
          ],
          Text(
            'The minor-safety boundary holds in every zone, no exceptions.',
            style: PorchType.hint(
              context,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Future<void> _selectZone(
    BuildContext context,
    UiSettings uiSettings,
    ContentZone zone,
  ) => selectContentZone(context, uiSettings, zone);
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({
    required this.zone,
    required this.selected,
    required this.showPolicy,
    required this.onSelect,
  });

  final ContentZone zone;
  final bool selected;
  final bool showPolicy;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final policy = GenerationPolicy.forZone(zone);
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(PorchRadius.md),
      child: Container(
        padding: const EdgeInsets.all(PorchSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PorchRadius.md),
          border: Border.all(
            color: selected
                ? AppColors.porchAmberOf(context)
                : AppColors.borderOf(context),
            width: selected ? 2 : 1,
          ),
          color: selected
              ? AppColors.porchAmberOf(context).withValues(alpha: 0.08)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    zone.label,
                    style: PorchType.bodySmall(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (zone.requiresAdult)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(PorchRadius.pill),
                      color: AppColors.negativeAccentOf(
                        context,
                      ).withValues(alpha: 0.15),
                    ),
                    child: Text(
                      '18+',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.negativeAccentOf(context),
                      ),
                    ),
                  ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.porchAmberOf(context),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(zone.description, style: PorchType.hint(context)),
            const SizedBox(height: 4),
            Text(
              zone.boundaryNote,
              style: PorchType.hint(
                context,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
            if (showPolicy) ...[
              const SizedBox(height: 8),
              Text(
                'Policy: SFW shaping ${policy.sfwPromptShaping ? 'on' : 'off'} · '
                'blocklist ${policy.blocklistFiltering ? 'on' : 'off'} · '
                'legal-only ${policy.legalBoundariesOnly ? 'on' : 'off'}',
                style: PorchType.caption(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
