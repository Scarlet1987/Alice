// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';

import 'package:front_porch_ai/ui/dialogs/npc_save_details.dart';
import 'package:front_porch_ai/ui/image_studio/studio_desk_copy.dart';

void main() {
  group('lockedAppearancePhrase', () {
    test('builds plain-English phrase from all fields', () {
      expect(
        lockedAppearancePhrase(
          age: '16',
          eyeColor: 'blue',
          hair: 'long black hair',
          features: 'scar on left cheek',
        ),
        '16 years old, blue eyes, long black hair, scar on left cheek',
      );
    });

    test('adds hair suffix when missing', () {
      expect(
        lockedAppearancePhrase(
          age: '',
          eyeColor: '',
          hair: 'red',
          features: '',
        ),
        'red hair',
      );
    });

    test('skips blank fields', () {
      expect(
        lockedAppearancePhrase(
          age: '',
          eyeColor: 'green',
          hair: '',
          features: '',
        ),
        'green eyes',
      );
    });

    test('empty when nothing locked in', () {
      expect(
        lockedAppearancePhrase(age: '', eyeColor: '', hair: '', features: ''),
        isEmpty,
      );
    });

    test('trims whitespace', () {
      expect(
        lockedAppearancePhrase(
          age: ' 24 ',
          eyeColor: '',
          hair: '',
          features: '',
        ),
        '24 years old',
      );
    });
  });

  group('NpcSaveDetails', () {
    test('holds edited NPC fields', () {
      const details = NpcSaveDetails(
        name: 'Mara',
        age: '16',
        eyeColor: 'blue',
        hair: 'red',
        features: 'freckles',
        personality: 'wry',
        description: 'the ferry master',
      );
      expect(details.name, 'Mara');
      expect(details.age, '16');
      expect(details.description, 'the ferry master');
    });
  });
}
