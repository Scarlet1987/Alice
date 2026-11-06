// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 state types: V9Page and V9Measurements, split out of
// alice_v9_state.dart so the state class (with its setters) stays
// under the 500-line god-file bar. No behaviour change.

/// v9 pages, in the preview's nav order.
enum V9Page { home, models, creator, profile }

/// Tailor's measurements, in the preview's file order, stored in cm.
/// Leg length is calculated from height and torso — no inseam field.
class V9Measurements {
  double waist;
  double shoulders;
  double height;
  double underbust;
  double bust;
  double thigh;
  double hips;
  String torsoLength; // short / average / long

  V9Measurements({
    this.waist = 70,
    this.shoulders = 42,
    this.height = 170,
    this.underbust = 75,
    this.bust = 90,
    this.thigh = 55,
    this.hips = 95,
    this.torsoLength = 'average',
  });

  double value(String id) {
    switch (id) {
      case 'waist':
        return waist;
      case 'shoulders':
        return shoulders;
      case 'height':
        return height;
      case 'underbust':
        return underbust;
      case 'bust':
        return bust;
      case 'thigh':
        return thigh;
      case 'hips':
        return hips;
      default:
        return 0;
    }
  }

  void set(String id, double cm) {
    switch (id) {
      case 'waist':
        waist = cm;
      case 'shoulders':
        shoulders = cm;
      case 'height':
        height = cm;
      case 'underbust':
        underbust = cm;
      case 'bust':
        bust = cm;
      case 'thigh':
        thigh = cm;
      case 'hips':
        hips = cm;
    }
  }

  String get line =>
      'Measurements (cm): waist ${waist.round()}, shoulders '
      '${shoulders.round()}, height ${height.round()}, underbust '
      '${underbust.round()}, bust ${bust.round()}, torso $torsoLength, '
      'thigh ${thigh.round()}, hips ${hips.round()}.';
}
