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

part of 'ui_settings.dart';

/// Effective colour/font getters, extracted from UiSettings so that file
/// stays under the 500-line god-file bar. No behaviour change: the same
/// resolution (theme override → preset → per-character → global), moved
/// whole into an extension in the same library, so private fields stay
/// accessible.
extension UiSettingsEffective on UiSettings {
  /// Get effective user bubble color.
  /// Resolution when a theme is active: theme override → theme preset (a chosen
  /// theme wins over per-character colors). No theme: per-character → global.
  Color getUserBubbleColor(
    CharacterCard? character, {
    ChatThemePreset? themePreset,
    ChatThemeOverrides? themeOverrides,
  }) {
    if (themeOverrides?.userBubbleColor != null && themePreset != null) {
      return themeOverrides!.resolvedUserBubbleColor(themePreset);
    }
    if (themePreset != null) return themePreset.defaultUserBubbleColor;
    final charColor = character?.frontPorchExtensions?.userBubbleColor;
    if (charColor != null) return charColor;
    return _isDark ? _globalUserBubbleColor : _lightUserBubbleColor;
  }

  /// Get effective user text color.
  /// Resolution when a theme is active: theme override → theme preset (a chosen
  /// theme wins over per-character colors). No theme: per-character → global.
  Color getUserTextColor(
    CharacterCard? character, {
    ChatThemePreset? themePreset,
    ChatThemeOverrides? themeOverrides,
  }) {
    if (themeOverrides?.userTextColor != null && themePreset != null) {
      return themeOverrides!.resolvedUserTextColor(themePreset);
    }
    if (themePreset != null) return themePreset.defaultUserTextColor;
    final charColor = character?.frontPorchExtensions?.userTextColor;
    if (charColor != null) return charColor;
    return _isDark ? _globalUserTextColor : _lightUserTextColor;
  }

  /// Get effective AI bubble color.
  /// Resolution when a theme is active: theme override → theme preset (a chosen
  /// theme wins over per-character colors). No theme: per-character → global.
  Color getAiBubbleColor(
    CharacterCard? character, {
    ChatThemePreset? themePreset,
    ChatThemeOverrides? themeOverrides,
  }) {
    if (themeOverrides?.aiBubbleColor != null && themePreset != null) {
      return themeOverrides!.resolvedAiBubbleColor(themePreset);
    }
    if (themePreset != null) return themePreset.defaultAiBubbleColor;
    final charColor = character?.frontPorchExtensions?.aiBubbleColor;
    if (charColor != null) return charColor;
    return _isDark ? _globalAiBubbleColor : _lightAiBubbleColor;
  }

  /// Get effective AI text color.
  /// Resolution when a theme is active: theme override → theme preset (a chosen
  /// theme wins over per-character colors). No theme: per-character → global.
  Color getAiTextColor(
    CharacterCard? character, {
    ChatThemePreset? themePreset,
    ChatThemeOverrides? themeOverrides,
  }) {
    if (themeOverrides?.aiTextColor != null && themePreset != null) {
      return themeOverrides!.resolvedAiTextColor(themePreset);
    }
    if (themePreset != null) return themePreset.defaultAiTextColor;
    final charColor = character?.frontPorchExtensions?.aiTextColor;
    if (charColor != null) return charColor;
    return _isDark ? _globalAiTextColor : _lightAiTextColor;
  }

  /// Get effective dialogue color.
  /// Resolution when a theme is active: theme override → theme preset (a chosen
  /// theme wins over per-character colors). No theme: per-character → global.
  Color getDialogueColor(
    CharacterCard? character, {
    ChatThemePreset? themePreset,
    ChatThemeOverrides? themeOverrides,
  }) {
    if (themeOverrides?.dialogueColor != null && themePreset != null) {
      return themeOverrides!.resolvedDialogueColor(themePreset);
    }
    if (themePreset != null) return themePreset.defaultDialogueColor;
    final charColor = character?.frontPorchExtensions?.dialogueColor;
    if (charColor != null) return charColor;
    return _isDark ? _globalDialogueColor : _lightDialogueColor;
  }

  /// Get effective action color.
  /// Resolution when a theme is active: theme override → theme preset (a chosen
  /// theme wins over per-character colors). No theme: per-character → global.
  Color getActionColor(
    CharacterCard? character, {
    ChatThemePreset? themePreset,
    ChatThemeOverrides? themeOverrides,
  }) {
    if (themeOverrides?.actionColor != null && themePreset != null) {
      return themeOverrides!.resolvedActionColor(themePreset);
    }
    if (themePreset != null) return themePreset.defaultActionColor;
    final charColor = character?.frontPorchExtensions?.actionColor;
    if (charColor != null) return charColor;
    return _isDark ? _globalActionColor : _lightActionColor;
  }

  /// Get effective chat font family.
  /// Resolution when a theme is active: theme override → theme preset (a chosen
  /// theme wins over per-character colors). No theme: per-character → global.
  String getChatFontFamily(
    CharacterCard? character, {
    ChatThemePreset? themePreset,
    ChatThemeOverrides? themeOverrides,
  }) {
    if (themeOverrides?.fontFamily != null && themePreset != null) {
      return themeOverrides!.resolvedFontFamily(themePreset);
    }
    if (themePreset != null) return themePreset.defaultFontFamily;
    final charFont = character?.frontPorchExtensions?.chatFontFamily;
    if (charFont != null) return charFont;
    return _globalChatFontFamily;
  }
}
