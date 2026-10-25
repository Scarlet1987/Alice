// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice edition Settings screen: the golden rule (static text, not a
// setting), where things live (UiSettings folder paths), the engines
// overview (live KoboldCpp state, selected image backend), engine
// resources (wired to the real engine settings and live hardware
// readings), content zone (wired to UiSettings with the shared
// zone-change flow), advanced paths (collapsed), and About & License
// (Alice edition credits).

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:front_porch_ai/ui/widgets/widgets.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/services/storage/storage.dart';
import 'package:front_porch_ai/ui/alice/alice_motion.dart';
import 'package:front_porch_ai/ui/alice/alice_widgets.dart';
import 'package:front_porch_ai/ui/settings/widgets/content_zone_select.dart';
import 'package:front_porch_ai/ui/settings/widgets/dead_dove/dead_dove_panel.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

part 'alice_settings_paths.dart';
part 'alice_settings_engines.dart';
part 'alice_settings_engine.dart';
part 'alice_settings_engine_budget.dart';
part 'alice_settings_image_engine.dart';
part 'alice_settings_zones.dart';
part 'alice_settings_about.dart';

/// Alice Settings screen. Everything here runs locally; the app holds
/// memory only while a story is running.
class AliceSettingsScreen extends StatefulWidget {
  const AliceSettingsScreen({super.key});

  @override
  State<AliceSettingsScreen> createState() => _AliceSettingsScreenState();
}

class _AliceSettingsScreenState extends State<AliceSettingsScreen> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _engineResourcesKey = GlobalKey();
  final GlobalKey _imageEngineKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Jumps the list to the detail card a Swap button names.
  void _jumpTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      alignment: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AliceScreenTitle(title: 'Settings'),
              const SizedBox(height: 2),
              Text(
                'Everything runs locally; the app holds memory only while '
                'a story is running.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 14),
              const _GoldenRuleCard(),
              const SizedBox(height: 12),
              const AliceWhereThingsLiveCard(),
              const SizedBox(height: 12),
              AliceEnginesCard(
                onSwapText: () => _jumpTo(_engineResourcesKey),
                onSwapImage: () => _jumpTo(_imageEngineKey),
              ),
              const SizedBox(height: 12),
              AliceEngineResourcesCard(key: _engineResourcesKey),
              const SizedBox(height: 12),
              AliceImageEngineCard(key: _imageEngineKey),
              const SizedBox(height: 12),
              const AliceContentZoneCard(),
              const SizedBox(height: 12),
              const AliceAdvancedPathsSection(),
              const SizedBox(height: 12),
              const AliceAboutSection(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The golden rule: gold accent bar, static ceiling text. It stands over
/// every setting and every world — it isn't a setting, so nothing can
/// switch it off.
class _GoldenRuleCard extends StatelessWidget {
  const _GoldenRuleCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AliceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AliceSectionHead(
            title: 'The golden rule',
            subtitle:
                'Stands over every setting and every world — it isn\u2019t '
                'a setting, so nothing can switch it off.',
            barColor: AppColors.porchAmber,
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              children: const [
                TextSpan(
                  text: 'The ceiling — the same for every world: ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text:
                      'However high a civilization climbs, the scale stops '
                      'at quantum entanglement — linked particles, instant '
                      'correlation across any distance. That\u2019s the top '
                      'reach, and it\u2019s not an absolute: no omnipotence, '
                      'nothing from nothing, no rewriting reality at a word. '
                      'Every power still needs energy in, matter to act on, '
                      'or a signal to ride.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Holds in every zone, at every detail level and Kardashev type — '
            'the gear check on the Main Character board enforces it.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
