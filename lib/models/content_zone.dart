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

/// The content zone chosen at account creation (and changeable later in
/// Settings). Determines what the generation policy allows. Safe Commons is
/// the default; the adult zones require 18+ verification.
enum ContentZone { commons, nsfw, deadDove }

/// Presentation copy for [ContentZone].
extension ContentZoneLabel on ContentZone {
  String get label => switch (this) {
    ContentZone.commons => 'Safe Commons',
    ContentZone.nsfw => 'NSFW',
    ContentZone.deadDove => 'Dead Dove',
  };

  /// Plain-English description of what the zone allows and blocks.
  String get description => switch (this) {
    ContentZone.commons =>
      'Full guardrails. SFW-only generation with strict legal and '
          'compliance filtering. The cozy default — safe for everyone.',
    ContentZone.nsfw =>
      'Adult content allowed; keeps only the hard legal boundaries. '
          '18+ only.',
    ContentZone.deadDove =>
      'The app adds no content filtering, no blocklists, and no refusal '
          'logic of its own — your prompts pass through untouched. 18+ only.',
  };

  /// Short note on what stays blocked even in this zone.
  String get boundaryNote => switch (this) {
    ContentZone.commons => 'Blocks adult content and anything illegal.',
    ContentZone.nsfw =>
      'Blocks illegal content, including sexual content involving minors.',
    ContentZone.deadDove =>
      'Blocks only the hard legal line: sexual content involving minors. '
          'Everything else passes through untouched.',
  };

  bool get requiresAdult => this != ContentZone.commons;

  static ContentZone fromName(String? name) => ContentZone.values.firstWhere(
    (v) => v.name == name,
    orElse: () => ContentZone.commons,
  );
}
