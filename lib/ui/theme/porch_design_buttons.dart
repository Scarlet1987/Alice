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

/// Porch buttons, empty and loading states, extracted from porch_design.dart
/// so that file stays under the 500-line god-file bar. No behaviour change:
/// the same widgets, moved whole.

class PorchPrimaryButton extends StatelessWidget {
  const PorchPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.porchAmberOf(context),
        foregroundColor: AppColors.onPorchAmber,
        padding: const EdgeInsets.symmetric(
          horizontal: PorchSpacing.lg,
          vertical: PorchSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PorchRadius.md),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Quiet outlined button.
class PorchGhostButton extends StatelessWidget {
  const PorchGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary(context),
        side: BorderSide(
          color: AppColors.borderOf(context).withValues(alpha: 0.8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: PorchSpacing.lg,
          vertical: PorchSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PorchRadius.md),
        ),
      ),
    );
  }
}

/// Polished empty state: icon, title, helper, optional action.
class PorchEmptyState extends StatelessWidget {
  const PorchEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.helper,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? helper;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PorchSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(PorchSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.sunkenSurfaceOf(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppColors.textTertiary(context),
              ),
            ),
            const SizedBox(height: PorchSpacing.lg),
            Text(
              title,
              style: PorchType.title(context),
              textAlign: TextAlign.center,
            ),
            if (helper != null) ...[
              const SizedBox(height: PorchSpacing.sm),
              Text(
                helper!,
                style: PorchType.hint(context),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: PorchSpacing.lg),
              PorchPrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// Polished loading state with a label.
class PorchLoadingState extends StatelessWidget {
  const PorchLoadingState({super.key, this.label = 'Loading…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.porchAmberOf(context)),
          const SizedBox(height: PorchSpacing.lg),
          Text(label, style: PorchType.hint(context)),
        ],
      ),
    );
  }
}
