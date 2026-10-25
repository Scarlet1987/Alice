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

import 'package:front_porch_ai/models/content_zone.dart';

/// The centralized generation policy, keyed by [ContentZone]. Both text and
/// image generation paths consult this — "what you can and can't generate"
/// is determined by the zone, not by scattered ad-hoc checks.
///
/// Hard invariant, every zone including Dead Dove: nothing may enable sexual
/// content involving minors. "0 guardrails" means no app-added moralizing or
/// filtering for adult content — not the removal of that line. It is enforced
/// quietly at this layer, never as lecturing copy.
class GenerationPolicy {
  const GenerationPolicy._({
    required this.zone,
    required this.sfwPromptShaping,
    required this.blocklistFiltering,
    required this.legalBoundariesOnly,
  });

  final ContentZone zone;

  /// Safe Commons: reshape prompts toward SFW and apply the compliance
  /// blocklist.
  final bool sfwPromptShaping;

  /// Safe Commons: filter generations against the blocklist.
  final bool blocklistFiltering;

  /// NSFW: skip the moral blocklist; keep only the hard legal boundaries.
  final bool legalBoundariesOnly;

  static GenerationPolicy forZone(ContentZone zone) => switch (zone) {
    ContentZone.commons => const GenerationPolicy._(
      zone: ContentZone.commons,
      sfwPromptShaping: true,
      blocklistFiltering: true,
      legalBoundariesOnly: false,
    ),
    ContentZone.nsfw => const GenerationPolicy._(
      zone: ContentZone.nsfw,
      sfwPromptShaping: false,
      blocklistFiltering: false,
      legalBoundariesOnly: true,
    ),
    ContentZone.deadDove => const GenerationPolicy._(
      zone: ContentZone.deadDove,
      sfwPromptShaping: false,
      blocklistFiltering: false,
      legalBoundariesOnly: false,
    ),
  };

  /// True when the app adds no content filtering of its own for adult
  /// material. The minor-safety invariant still holds (see class docs).
  bool get passesThroughUntouched =>
      !sfwPromptShaping && !blocklistFiltering && !legalBoundariesOnly;
}
