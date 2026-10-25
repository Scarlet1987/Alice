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

import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/storage/storage.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// Reads the current [DetailLevel] from the ambient [StorageService].
extension DetailContext on BuildContext {
  DetailLevel get detailLevel =>
      Provider.of<StorageService>(this, listen: false).uiSettings.detailLevel;
}

/// Shows [child] only when the user's detail level reveals [required].
/// Use to keep advanced knobs and jargon out of the way in Simple mode.
///
/// Progressive disclosure runs both ways: at or above [required] the child
/// shows inline; below it, the child hides behind a "Show advanced options"
/// expander. The detail level is a default, never a cage — Simple users can
/// still reach every knob without switching modes.
class DetailGate extends StatelessWidget {
  const DetailGate({
    super.key,
    required this.required,
    required this.child,
    this.label = 'Show advanced options',
  });

  final DetailLevel required;
  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) {
    final level = Provider.of<StorageService>(context).uiSettings.detailLevel;
    if (level.reveals(required)) return child;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Icon(
              Icons.tune,
              size: 16,
              color: AppColors.porchAmberOf(context),
            ),
            const SizedBox(width: PorchSpacing.sm),
            Text(
              label,
              style: TextStyle(
                color: AppColors.porchAmberOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        children: [child],
      ),
    );
  }
}

/// The prominent "How much detail do you want?" control. Persisted in
/// [UiSettings]; screens gate advanced knobs on it via [DetailGate].
class DetailLevelControl extends StatelessWidget {
  const DetailLevelControl({super.key, this.compact = false});

  /// Compact renders without the surrounding card (for tight layouts).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final uiSettings = Provider.of<StorageService>(context).uiSettings;
    final level = uiSettings.detailLevel;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How much detail do you want?', style: PorchType.title(context)),
        const SizedBox(height: PorchSpacing.xs),
        Text(
          'Simple hides advanced knobs and jargon. Advanced reveals '
          'everything.',
          style: PorchType.hint(context),
        ),
        const SizedBox(height: PorchSpacing.md),
        PorchSegmentedControl<DetailLevel>(
          value: level,
          onChanged: uiSettings.setDetailLevel,
          options: const [
            PorchSegmentOption(
              value: DetailLevel.simple,
              label: 'Simple',
              icon: Icons.spa_outlined,
            ),
            PorchSegmentOption(
              value: DetailLevel.balanced,
              label: 'Balanced',
              icon: Icons.tune,
            ),
            PorchSegmentOption(
              value: DetailLevel.advanced,
              label: 'Advanced',
              icon: Icons.engineering_outlined,
            ),
          ],
        ),
        const SizedBox(height: PorchSpacing.sm),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            level.description,
            key: ValueKey(level),
            style: PorchType.caption(context),
          ),
        ),
      ],
    );
    if (compact) return body;
    return PorchCard(
      accent: AppColors.porchAmberOf(context).withValues(alpha: 0.6),
      child: body,
    );
  }
}
