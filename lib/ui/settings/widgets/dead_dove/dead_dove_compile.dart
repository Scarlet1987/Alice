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

// Dead Dove step 5: compile the ticks into the red/yellow/green lists
// the model follows, plus the separate story brief. Shows a stale
// notice when ticks change after compiling.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';

import 'dead_dove_checklist_state.dart';
import 'dead_dove_topic_list.dart';
import 'dead_dove_topics.dart';

/// Step 5: compile lists.
class DeadDoveCompile extends StatelessWidget {
  const DeadDoveCompile({super.key, required this.state});

  final DeadDoveChecklistState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final compiled = state.compiled;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compile your lists',
              style: PorchType.body(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'Compiling turns your ticks into the two things the model '
              'follows: the Top 100 list and the story brief.',
              style: PorchType.hint(context),
            ),
            const SizedBox(height: PorchSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Done ticking?',
                        style: PorchType.bodySmall(
                          context,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'See exactly what you\u2019ve set — red, yellow and '
                        'green for the Top 100, plus the separate story brief.',
                        style: PorchType.hint(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PorchSpacing.sm),
                ElevatedButton(
                  onPressed: state.compile,
                  child: const Text('Compile list'),
                ),
              ],
            ),
            if (compiled != null) ...[
              const SizedBox(height: PorchSpacing.md),
              if (state.isStale)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(PorchSpacing.sm),
                  margin: const EdgeInsets.only(bottom: PorchSpacing.sm),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(PorchRadius.sm),
                    color: AppColors.porchHoneyOf(
                      context,
                    ).withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.porchHoneyOf(
                        context,
                      ).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Your ticks have changed since you compiled — compile '
                    'again to update this list.',
                    style: PorchType.bodySmall(context),
                  ),
                ),
              _CompiledSection(
                title: 'Your compiled list',
                subtitle: 'This is what the model follows.',
                topics: kDeadDoveTop100,
                state: state,
                openLine:
                    '${state.uncheckedCount(kDeadDoveTop100)} of the 100 '
                    'topics are unchecked — in Dead Dove, those still go.',
              ),
              const SizedBox(height: PorchSpacing.md),
              _CompiledSection(
                title: 'Your story brief',
                subtitle:
                    'Story & content only — compiled separately from the Top '
                    '100 list above.',
                topics: kDeadDoveStoryTopics,
                state: state,
                openLine:
                    '${state.uncheckedCount(kDeadDoveStoryTopics)} of the 48 '
                    'story topics are unchecked — those can still happen.',
              ),
              if (compiled.fantasy.isNotEmpty) ...[
                const SizedBox(height: PorchSpacing.sm),
                Text(
                  'Fantasy: ${compiled.fantasy}',
                  style: PorchType.bodySmall(context),
                ),
              ],
              if (compiled.stopWord.isNotEmpty) ...[
                Text(
                  'Stop word: "${compiled.stopWord}"',
                  style: PorchType.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _CompiledSection extends StatelessWidget {
  const _CompiledSection({
    required this.title,
    required this.subtitle,
    required this.topics,
    required this.state,
    required this.openLine,
  });

  final String title;
  final String subtitle;
  final List<DeadDoveTopic> topics;
  final DeadDoveChecklistState state;
  final String openLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: PorchType.body(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(subtitle, style: PorchType.hint(context)),
        const SizedBox(height: PorchSpacing.sm),
        _CompiledColumn(
          level: DeadDoveLevel.hard,
          title: 'Red — Never',
          topics: state.topicsAt(topics, DeadDoveLevel.hard),
          emptyText: 'No hard limits ticked.',
        ),
        _CompiledColumn(
          level: DeadDoveLevel.allow,
          title: 'Green — Allowed',
          topics: state.topicsAt(topics, DeadDoveLevel.allow),
          emptyText:
              'Nothing explicitly allowed yet — remember, unchecked topics '
              'still go.',
        ),
        Text(
          'Yellow — Caution',
          style: PorchType.bodySmall(
            context,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Soft — ask first',
          style: PorchType.caption(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        for (final t in state.topicsAt(topics, DeadDoveLevel.soft))
          _CompiledRow(topic: t, level: DeadDoveLevel.soft),
        if (state.topicsAt(topics, DeadDoveLevel.soft).isEmpty)
          Text('No soft limits ticked.', style: PorchType.hint(context)),
        const SizedBox(height: 4),
        Text(
          'Caution — slow down',
          style: PorchType.caption(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        for (final t in state.topicsAt(topics, DeadDoveLevel.caution))
          _CompiledRow(topic: t, level: DeadDoveLevel.caution),
        if (state.topicsAt(topics, DeadDoveLevel.caution).isEmpty)
          Text('No caution limits ticked.', style: PorchType.hint(context)),
        const SizedBox(height: PorchSpacing.sm),
        Text(openLine, style: PorchType.hint(context)),
      ],
    );
  }
}

class _CompiledColumn extends StatelessWidget {
  const _CompiledColumn({
    required this.level,
    required this.title,
    required this.topics,
    required this.emptyText,
  });

  final DeadDoveLevel level;
  final String title;
  final List<DeadDoveTopic> topics;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final color = DeadDoveLevelColors.of(context, level);
    return Padding(
      padding: const EdgeInsets.only(bottom: PorchSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$title ',
                style: PorchType.bodySmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PorchRadius.pill),
                  color: color.withValues(alpha: 0.15),
                ),
                child: Text(
                  '${topics.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (topics.isEmpty)
            Text(emptyText, style: PorchType.hint(context))
          else
            for (final t in topics) _CompiledRow(topic: t, level: level),
        ],
      ),
    );
  }
}

class _CompiledRow extends StatelessWidget {
  const _CompiledRow({required this.topic, required this.level});

  final DeadDoveTopic topic;
  final DeadDoveLevel level;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 2),
      child: Text('• ${topic.label}', style: PorchType.bodySmall(context)),
    );
  }
}
