// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

// The self-updater's Linux asset is Elaina's versioned .deb — the name
// embeds the version, so it is matched by pattern, not by an exact-name
// constant. These pins keep the pattern honest against what her releases
// actually publish (and what they must never select instead).

import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/services/update_service.dart';

void main() {
  group('UpdateService.isLinuxDebAssetName', () {
    test('matches the .deb her releases publish', () {
      expect(
        UpdateService.isLinuxDebAssetName(
          'front-porch-ai_1.5.0-alice7_amd64.deb',
        ),
        isTrue,
      );
      expect(
        UpdateService.isLinuxDebAssetName(
          'front-porch-ai_1.5.1-alice8_amd64.deb',
        ),
        isTrue,
      );
    });

    test('does not match the Flatpak bundle or the retired AppImage names', () {
      expect(
        UpdateService.isLinuxDebAssetName('RabbitHole-alice7.flatpak'),
        isFalse,
      );
      expect(
        UpdateService.isLinuxDebAssetName('Front_Porch_AI-Linux.AppImage'),
        isFalse,
      );
      expect(
        UpdateService.isLinuxDebAssetName(
          'Front_Porch_AI_Nightly-Linux.AppImage',
        ),
        isFalse,
      );
    });

    test('does not match other platforms or lookalikes', () {
      expect(
        UpdateService.isLinuxDebAssetName('Front_Porch_AI_Setup.exe'),
        isFalse,
      );
      expect(
        UpdateService.isLinuxDebAssetName('front-porch-ai_1.5.0_arm64.deb'),
        isFalse,
      );
      expect(
        UpdateService.isLinuxDebAssetName('front-porch-ai_amd64.deb'),
        isFalse,
      );
      expect(UpdateService.isLinuxDebAssetName(''), isFalse);
    });
  });
}
