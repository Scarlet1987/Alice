// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Details the user locked in for a newly-detected NPC before saving.
/// Returned by [SceneGuestDetectedDialog]; null means dismissed.
class NpcSaveDetails {
  const NpcSaveDetails({
    required this.name,
    this.age = '',
    this.eyeColor = '',
    this.hair = '',
    this.features = '',
    this.personality = '',
    this.description = '',
  });

  final String name;
  final String age;
  final String eyeColor;
  final String hair;
  final String features;
  final String personality;
  final String description;
}
