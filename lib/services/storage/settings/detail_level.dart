// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This file is part of Front Porch AI.
//
// Front Porch AI is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

/// How much detail and control the UI exposes. The user picks this once in
/// Settings ("How much detail do you want?"); screens hide or reveal knobs
/// accordingly. Persisted in [UiSettings].
enum DetailLevel {
  /// Friendly essentials only. Advanced knobs, jargon and fine-tuning stay
  /// hidden.
  simple,

  /// The full standard experience. A comfortable middle ground.
  balanced,

  /// Everything: every knob, preset editor, and advanced section.
  advanced,
}

/// Presentation copy for [DetailLevel].
extension DetailLevelLabel on DetailLevel {
  String get label => switch (this) {
    DetailLevel.simple => 'Simple',
    DetailLevel.balanced => 'Balanced',
    DetailLevel.advanced => 'Advanced',
  };

  String get description => switch (this) {
    DetailLevel.simple =>
      'Just the essentials. Advanced settings stay out of the way.',
    DetailLevel.balanced => 'The full standard experience. Nothing hidden.',
    DetailLevel.advanced =>
      'Every knob and fine-tuning option, everywhere.',
  };

  /// True when this level reveals content gated at [required].
  bool reveals(DetailLevel required) => index >= required.index;

  static DetailLevel fromName(String? name) => DetailLevel.values.firstWhere(
    (v) => v.name == name,
    orElse: () => DetailLevel.balanced,
  );
}
