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

// Reusable Dead Dove topic checklist: search field, bulk actions, live
// counts, and the four colour columns (green allow, red hard, yellow
// soft, yellow caution). One topic holds one level at a time; tapping a
// topic cycles it through the levels.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';

import 'dead_dove_checklist_state.dart';
import 'dead_dove_topics.dart';

/// Colours for the four limit levels, matching the preview.
class DeadDoveLevelColors {
  static Color of(BuildContext context, DeadDoveLevel level) {
    switch (level) {
      case DeadDoveLevel.allow:
        return AppColors.bondHighOf(context);
      case DeadDoveLevel.hard:
        return AppColors.lustAccentOf(context);
      case DeadDoveLevel.soft:
        return AppColors.porchHoneyOf(context);
      case DeadDoveLevel.caution:
        return AppColors.porchAmberOf(context);
    }
  }
}

/// A single topic row. Tapping cycles the level; the dot shows the
/// current level (or a hollow dot when unchecked).
class DeadDoveTopicRow extends StatelessWidget {
  const DeadDoveTopicRow({
    super.key,
    required this.topic,
    required this.level,
    required this.onTap,
  });

  final DeadDoveTopic topic;
  final DeadDoveLevel? level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentLevel = level;
    final dotColor = currentLevel == null
        ? AppColors.borderOf(context)
        : DeadDoveLevelColors.of(context, currentLevel);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PorchRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: PorchSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentLevel == null ? Colors.transparent : dotColor,
                border: Border.all(color: dotColor, width: 2),
              ),
            ),
            const SizedBox(width: PorchSpacing.sm),
            Expanded(
              child: Text(topic.label, style: PorchType.bodySmall(context)),
            ),
            if (currentLevel != null)
              Text(
                currentLevel.label,
                style: PorchType.caption(context).copyWith(color: dotColor),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full checklist section: search, bulk actions, counts, and the topic
/// list grouped by category. Used for both the Top 100 and the story list.
class DeadDoveTopicChecklist extends StatefulWidget {
  const DeadDoveTopicChecklist({
    super.key,
    required this.topics,
    required this.state,
    required this.searchHint,
    required this.allowAllLabel,
    required this.hardAllLabel,
    required this.clearAllLabel,
    required this.uncheckedLabel,
  });

  final List<DeadDoveTopic> topics;
  final DeadDoveChecklistState state;
  final String searchHint;
  final String allowAllLabel;
  final String hardAllLabel;
  final String clearAllLabel;
  final String uncheckedLabel;

  @override
  State<DeadDoveTopicChecklist> createState() =>
      _DeadDoveTopicChecklistState();
}

class _DeadDoveTopicChecklistState extends State<DeadDoveTopicChecklist> {
  String _query = '';

  List<DeadDoveTopic> get _filtered {
    if (_query.isEmpty) return widget.topics;
    final q = _query.toLowerCase();
    return widget.topics
        .where(
          (t) =>
              t.label.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final filtered = _filtered;
        // Group by category, preserving order.
        final categories = <String>[];
        final byCategory = <String, List<DeadDoveTopic>>{};
        for (final t in filtered) {
          (byCategory[t.category] ??= []).add(t);
          if (!categories.contains(t.category)) categories.add(t.category);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search, size: 18),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            if (_query.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${filtered.length} of ${widget.topics.length} topics',
                  style: PorchType.caption(context),
                ),
              ),
            const SizedBox(height: PorchSpacing.sm),
            Wrap(
              spacing: PorchSpacing.sm,
              runSpacing: PorchSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Bulk:', style: PorchType.caption(context)),
                _BulkButton(
                  label: widget.allowAllLabel,
                  onPressed: () =>
                      state.setAll(widget.topics, DeadDoveLevel.allow),
                ),
                _BulkButton(
                  label: widget.hardAllLabel,
                  onPressed: () =>
                      state.setAll(widget.topics, DeadDoveLevel.hard),
                ),
                _BulkButton(
                  label: widget.clearAllLabel,
                  onPressed: () => state.setAll(widget.topics, null),
                ),
              ],
            ),
            const SizedBox(height: PorchSpacing.sm),
            Wrap(
              spacing: PorchSpacing.xs,
              runSpacing: PorchSpacing.xs,
              children: [
                _CountChip(
                  label:
                      '${state.countOf(widget.topics, DeadDoveLevel.allow)} allowed',
                  color: DeadDoveLevelColors.of(
                    context,
                    DeadDoveLevel.allow,
                  ),
                ),
                _CountChip(
                  label:
                      '${state.countOf(widget.topics, DeadDoveLevel.hard)} hard limits',
                  color: DeadDoveLevelColors.of(
                    context,
                    DeadDoveLevel.hard,
                  ),
                ),
                _CountChip(
                  label:
                      '${state.countOf(widget.topics, DeadDoveLevel.soft)} soft limits',
                  color: DeadDoveLevelColors.of(
                    context,
                    DeadDoveLevel.soft,
                  ),
                ),
                _CountChip(
                  label:
                      '${state.countOf(widget.topics, DeadDoveLevel.caution)} caution',
                  color: DeadDoveLevelColors.of(
                    context,
                    DeadDoveLevel.caution,
                  ),
                ),
                _CountChip(
                  label:
                      '${state.uncheckedCount(widget.topics)} ${widget.uncheckedLabel}',
                  color: AppColors.borderOf(context),
                ),
              ],
            ),
            const SizedBox(height: PorchSpacing.md),
            for (final category in categories) ...[
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 4,
                  top: PorchSpacing.sm,
                ),
                child: Text(
                  category,
                  style: PorchType.bodySmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              for (final topic in byCategory[category]!)
                DeadDoveTopicRow(
                  topic: topic,
                  level: state.levelOf(topic.id),
                  onTap: () => state.cycleLevel(topic.id),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _BulkButton extends StatelessWidget {
  const _BulkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PorchRadius.pill),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
