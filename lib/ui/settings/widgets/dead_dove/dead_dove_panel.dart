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

// Dead Dove negotiated-limits panel: the six steps from the preview.
// 1) What each colour means, 2) fantasy & stop word, 3) Top 100 tick
// list, 4) story & content checklist, 5) compile, 6) your own models.
// Shown inside the Content zone card while Dead Dove is the active zone.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/theme/porch_design.dart';

import 'dead_dove_checklist_state.dart';
import 'dead_dove_compile.dart';
import 'dead_dove_models.dart';
import 'dead_dove_topic_list.dart';
import 'dead_dove_topics.dart';

/// The full Dead Dove panel. Owns its [DeadDoveChecklistState].
class DeadDovePanel extends StatefulWidget {
  const DeadDovePanel({super.key});

  @override
  State<DeadDovePanel> createState() => _DeadDovePanelState();
}

class _DeadDovePanelState extends State<DeadDovePanel> {
  late final DeadDoveChecklistState _state = DeadDoveChecklistState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(),
        const SizedBox(height: PorchSpacing.md),
        _Step(number: '1', child: _ColorMeanings()),
        _Step(number: '2', child: _FantasyStep(state: _state)),
        _Step(
          number: '3',
          child: DeadDoveTopicChecklist(
            topics: kDeadDoveTop100,
            state: _state,
            searchHint: 'Search the Top 100 — try "rope", "wax", "latex"…',
            allowAllLabel: 'Allow all 100',
            hardAllLabel: 'Hard-limit all 100',
            clearAllLabel: 'Clear all — everything goes',
            uncheckedLabel: 'unchecked — anything goes',
          ),
        ),
        _Step(
          number: '4',
          title: 'Story & content — what can happen in the story',
          subtitle:
              'Separate from the Top 100: can characters die, what kind of '
              'conflict, how it ends. Same rule — one topic, one colour, '
              'unchecked means it can happen.',
          child: DeadDoveTopicChecklist(
            topics: kDeadDoveStoryTopics,
            state: _state,
            searchHint: 'Search story & content — try "die", "war", "happy"…',
            allowAllLabel: 'Allow all 48',
            hardAllLabel: 'Don\u2019t allow all 48',
            clearAllLabel: 'Clear all — everything can happen',
            uncheckedLabel: 'unchecked — it can happen',
          ),
        ),
        _Step(number: '5', child: DeadDoveCompile(state: _state)),
        _Step(number: '6', child: DeadDoveModels(state: _state)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dead Dove · Your negotiated limits',
          style: PorchType.caption(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.porchAmberOf(context),
          ),
        ),
        const SizedBox(height: 4),
        Text('One list. Your rules.', style: PorchType.sectionTitle(context)),
        const SizedBox(height: 4),
        Text(
          'Dead Dove is consensual non-consent: you negotiate here, up front '
          '— then, inside the lines you set, any fantasy you define goes and '
          'the app adds no filtering of its own. Work top to bottom: colours '
          '→ fantasy → Top 100 → story → compile.',
          style: PorchType.hint(context),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, this.title, this.subtitle, required this.child});

  final String number;
  final String? title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: PorchSpacing.md),
      padding: const EdgeInsets.all(PorchSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PorchRadius.md),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.porchAmberOf(
                    context,
                  ).withValues(alpha: 0.15),
                ),
                child: Text(
                  number,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.porchAmberOf(context),
                  ),
                ),
              ),
              const SizedBox(width: PorchSpacing.sm),
              if (title != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: PorchType.body(context).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(subtitle!, style: PorchType.hint(context)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: PorchSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _ColorMeanings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What each colour means',
          style: PorchType.body(
            context,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          'One topic holds one colour at a time. Ticking it anywhere unticks '
          'it everywhere else.',
          style: PorchType.hint(context),
        ),
        const SizedBox(height: PorchSpacing.sm),
        _ColorDef(
          level: DeadDoveLevel.hard,
          title: 'Red — Hard limit · Never',
          body:
              'Absolutely not. It won\u2019t be generated, and a scene heading '
              'that way stops. It only changes here, outside play.',
        ),
        _ColorDef(
          level: DeadDoveLevel.allow,
          title: 'Green — Allow · Yes',
          body:
              'An explicit yes. You have looked at this topic and you want it '
              'in play.',
        ),
        _ColorDef(
          level: DeadDoveLevel.soft,
          title: 'Yellow — Soft limit · Ask first',
          body:
              'Hesitant, not a never. Only after an explicit check-in, '
              'approached slowly — and it can become a hard limit at any moment.',
        ),
        _ColorDef(
          level: DeadDoveLevel.caution,
          title: 'Yellow — Caution · Slow down',
          body:
              'Allowed, but gently. Ease in, keep it lighter, and watch for '
              'the stop word instead of pushing through.',
        ),
        const SizedBox(height: PorchSpacing.sm),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Unchecked = anything goes. ',
                style: PorchType.bodySmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text:
                    'A topic on no list has no limit set — silence is permission '
                    'here, not a maybe. If it matters, tick it.',
                style: PorchType.bodySmall(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: PorchSpacing.sm),
        Container(
          padding: const EdgeInsets.all(PorchSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PorchRadius.sm),
            color: AppColors.negativeAccentOf(
              context,
            ).withValues(alpha: 0.08),
            border: Border.all(
              color: AppColors.negativeAccentOf(
                context,
              ).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: AppColors.negativeAccentOf(context),
              ),
              const SizedBox(width: PorchSpacing.sm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'One line is not yours to move: ',
                        style: PorchType.bodySmall(
                          context,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            'sexual content involving minors is always blocked, '
                            'in every zone, whatever is ticked here. Everything '
                            'else on this page is your call.',
                        style: PorchType.bodySmall(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorDef extends StatelessWidget {
  const _ColorDef({
    required this.level,
    required this.title,
    required this.body,
  });

  final DeadDoveLevel level;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final color = DeadDoveLevelColors.of(context, level);
    return Padding(
      padding: const EdgeInsets.only(bottom: PorchSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: PorchSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PorchType.bodySmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                Text(body, style: PorchType.hint(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FantasyStep extends StatelessWidget {
  const _FantasyStep({required this.state});

  final DeadDoveChecklistState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your fantasy & stop word',
            style: PorchType.body(context).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Optional, in your own words. The stop word ends any scene at '
            'once — full stop, no in-character override.',
            style: PorchType.hint(context),
          ),
          const SizedBox(height: PorchSpacing.sm),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Fantasy',
              hintText:
                  'Describe the fantasy — the scene, the dynamic, what '
                  '"non-consent" looks like inside the fiction…',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: state.setFantasy,
          ),
          const SizedBox(height: PorchSpacing.sm),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Stop word',
              hintText: 'e.g. "red" or "porch light"',
              border: OutlineInputBorder(),
            ),
            onChanged: state.setStopWord,
          ),
        ],
      ),
    );
  }
}
