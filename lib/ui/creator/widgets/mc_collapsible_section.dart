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

// Collapsible section for the Main Character board: a header row with an
// accent bar, title, subtitle, and chevron; tapping folds/unfolds the body.
// Sections start folded so the user focuses only on what they're filling in.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';

/// A collapsible section with an accent bar, title, and subtitle.
class McCollapsibleSection extends StatefulWidget {
  const McCollapsibleSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
    this.initiallyOpen = false,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;
  final bool initiallyOpen;

  @override
  State<McCollapsibleSection> createState() => _McCollapsibleSectionState();
}

class _McCollapsibleSectionState extends State<McCollapsibleSection> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return PorchCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(PorchRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(PorchSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: widget.accent,
                    ),
                  ),
                  const SizedBox(width: PorchSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: PorchType.body(context).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: PorchType.hint(context),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _open
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppColors.textTertiary(context),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PorchSpacing.md,
                0,
                PorchSpacing.md,
                PorchSpacing.md,
              ),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}
