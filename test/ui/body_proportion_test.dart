// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';

import 'package:front_porch_ai/ui/image_studio/studio_desk_copy.dart';

void main() {
  group('BodyProportion head-count key', () {
    test('setting values round-trip', () {
      for (final p in BodyProportion.values) {
        expect(
          bodyProportionFromSetting(bodyProportionSetting(p)),
          p,
        );
      }
    });

    test('unknown setting falls back to adult', () {
      expect(bodyProportionFromSetting('nonsense'), BodyProportion.adult);
      expect(bodyProportionFromSetting(''), BodyProportion.adult);
    });

    test('labels are plain English with head ranges', () {
      expect(bodyProportionLabel(BodyProportion.child), contains('4–5 heads'));
      expect(bodyProportionLabel(BodyProportion.teen), contains('6–7 heads'));
      expect(bodyProportionLabel(BodyProportion.adult), contains('7–8 heads'));
      expect(bodyProportionLabel(BodyProportion.off), 'Off');
    });

    test('prompt phrases carry the head count', () {
      expect(bodyProportionPrompt(BodyProportion.child), contains('5 heads'));
      expect(bodyProportionPrompt(BodyProportion.teen), contains('6 heads'));
      expect(bodyProportionPrompt(BodyProportion.adult), contains('8 heads'));
    });

    test('off injects nothing', () {
      expect(bodyProportionPrompt(BodyProportion.off), isEmpty);
    });

    test('key explainer is plain English', () {
      expect(kBodyProportionKey, contains('1 head'));
      expect(kBodyProportionKey, isNot(contains('denoise')));
      expect(kBodyProportionKey, isNot(contains('LoRA')));
    });
  });
}
