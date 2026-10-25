// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/porch_theme_scope.dart';

class AppColors {
  AppColors._();

  /// True when the OLED true-black theme variant is active for this build.
  static bool isOled(BuildContext context) =>
      PorchThemeScope.oledBlackOf(context);

  // ---------------------------------------------------------------------------
  // OLED true-black variant (pure black grounds for OLED screens)
  // ---------------------------------------------------------------------------

  /// True-black scaffold background for the OLED variant.
  static const Color oledBackground = Color(0xFF000000);

  /// True-black card fill for the OLED variant.
  static const Color oledCard = Color(0xFF0A0A0C);

  /// True-black surface fill for the OLED variant.
  static const Color oledSurface = Color(0xFF101013);

  /// Resolves dark/light, preferring the OLED true-black variant when active.
  static Color resolveOled(
    BuildContext context,
    Color dark,
    Color light,
    Color oled,
  ) => isOled(context) ? oled : resolve(context, dark, light);

  /// Surface background for dialogs, containers, and panels.
  static const Color surface = Color(0xFF0B3A33);

  /// Deep background for scaffolds and page-level backgrounds.
  static const Color background = Color(0xFF04231F);

  /// Card/container background for cards, dropdowns, and elevated surfaces.
  static const Color card = Color(0xFF08302A);

  // ---------------------------------------------------------------------------
  // Chat appearance defaults
  // ---------------------------------------------------------------------------

  /// Default color for the user's message bubbles.
  static const Color userBubble = Color(0xFF2F7FE0);

  /// Default color for the user's message text.
  static const Color userText = Colors.white;

  /// Default color for the AI's message bubbles.
  static const Color aiBubble = Color(0xFF0E3F38);

  /// Default color for the AI's message text.
  static const Color aiText = Colors.white;

  /// Default color for quoted/dialogue text ("...").
  static const Color dialogue = Color(0xFFF9A8D4);

  /// Default color for action/emote text (*...*).
  static const Color action = Color(0xFF93C5FD);

  // ---------------------------------------------------------------------------
  // Light-mode backgrounds
  // ---------------------------------------------------------------------------

  /// Light-mode scaffold background (mint-white for long-session comfort).
  static const Color lightBackground = Color(0xFFF4FAF8);

  /// Light-mode card/container background.
  static const Color lightCard = Colors.white;

  /// Light-mode surface background for dialogs and panels (mint tint).
  static const Color lightSurface = Color(0xFFE7F3F0);

  // ---------------------------------------------------------------------------
  // Container surface for dropdowns, dialogs, and input fields
  // ---------------------------------------------------------------------------

  /// Dark container surface (slightly lighter than [card] for visual layering).
  static const Color surfaceContainer = Color(0xFF0B3A33);

  /// Light container surface for the same purpose (mint tint).
  static const Color surfaceContainerLight = Color(0xFFEEF7F4);

  /// Subtle border color for cards/panels in light mode (defines shape without harsh contrast).
  static const Color lightBorder = Color(0xFFB9D8D1);

  /// Brightness-aware container surface.
  static Color surfaceContainerOf(BuildContext context) =>
      resolve(context, surfaceContainer, surfaceContainerLight);

  // ---------------------------------------------------------------------------
  // Chat appearance defaults — light mode
  // ---------------------------------------------------------------------------

  /// Default user bubble color in light mode.
  static const Color userBubbleLight = Color(0xFF3B82F6);

  /// Default user text color in light mode.
  static const Color userTextLight = Colors.white;

  /// Default AI bubble color in light mode.
  static const Color aiBubbleLight = Color(0xFFE5E7EB);

  /// Default AI text color in light mode.
  static const Color aiTextLight = Colors.black87;

  /// Default dialogue color in light mode.
  static const Color dialogueLight = Color(0xFFB03060);

  /// Default action color in light mode.
  static const Color actionLight = Color(0xFF1565C0);

  // ---------------------------------------------------------------------------
  // Brightness-aware text/background helpers
  // ---------------------------------------------------------------------------

  /// True when the current brightness is light.
  static bool isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  /// Primary text color for the current brightness.
  static Color textPrimary(BuildContext context) =>
      isLight(context) ? Colors.black87 : Colors.white;

  /// Secondary text color for the current brightness.
  static Color textSecondary(BuildContext context) =>
      isLight(context) ? Colors.black54 : Colors.white70;

  /// Tertiary text color for the current brightness.
  static Color textTertiary(BuildContext context) =>
      isLight(context) ? Colors.black45 : Colors.white38;

  /// Primary icon color (reuses exact isLight + ternary scaffold of textPrimary; no new logic).
  static Color iconPrimary(BuildContext context) =>
      isLight(context) ? Colors.black87 : Colors.white;

  /// Secondary / muted icon color (matches textSecondary pattern).
  static Color iconSecondary(BuildContext context) =>
      isLight(context) ? Colors.black54 : Colors.white70;

  /// Resolves a dark/light color pair based on current brightness.
  static Color resolve(BuildContext context, Color dark, Color light) =>
      isLight(context) ? light : dark;

  /// Background for the current brightness (true black in OLED mode).
  static Color backgroundOf(BuildContext context) =>
      resolveOled(context, background, lightBackground, oledBackground);

  /// Card color for the current brightness (true black in OLED mode).
  static Color cardOf(BuildContext context) =>
      resolveOled(context, card, lightCard, oledCard);

  /// Surface color for the current brightness (true black in OLED mode).
  static Color surfaceOf(BuildContext context) =>
      resolveOled(context, surface, lightSurface, oledSurface);

  /// Subtle border color for the current brightness (reuses resolve scaffold; no new logic).
  static Color borderOf(BuildContext context) =>
      resolve(context, const Color(0xFF1C554B), lightBorder);

  /// Soft border (the preview's --border-soft): card edges and the nav
  /// rail's right edge — a whisper under [borderOf].
  static const Color borderSoft = Color(0xFF123F37);
  static const Color borderSoftLight = Color(0xFFD9ECE7);
  static Color borderSoftOf(BuildContext context) =>
      resolve(context, borderSoft, borderSoftLight);

  // ---------------------------------------------------------------------------
  // Process log / terminal output colors
  // ---------------------------------------------------------------------------

  /// Color for error/fail/fatal lines in process logs.
  static const Color logError = Color(0xFFFF6B6B);

  /// Color for warning lines in process logs.
  static const Color logWarn = Color(0xFFFFD93D);

  /// Color for ready/server-listen lines.
  static const Color logReady = Color(0xFF69F0AE);

  /// Color for loading/starting lines.
  static const Color logLoading = Color(0xFF93C5FD);

  /// Default color for normal lines.
  static const Color logDefault = Color(0xFF86EFAC);

  // ---------------------------------------------------------------------------
  // Creator wizard selected card backgrounds (for mode/backend chips)
  // ---------------------------------------------------------------------------

  /// Selected background for creator mode and backend selection cards.
  static const Color creatorSelectedCard = Color(0xFF1E3A5F);
  static const Color creatorSelectedCardLight = Color(0xFFE0F2FE);

  // ---------------------------------------------------------------------------
  // Preset palette for color pickers
  // ---------------------------------------------------------------------------

  /// Palette shown in color picker dialogs (no duplicates).
  static const List<Color> presetColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
    Color(0xFF6366F1), // Indigo
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
  ];

  // ---------------------------------------------------------------------------
  // Realism form / optional accents (semantic for exclusive AppColors use in
  // refactored creator/edit/group surfaces incl. authority/verif toggles,
  // section headers, bond/trust/need sliders, master containers).
  // All literals confined here; UI code uses only AppColors.*Of / consts.
  // ---------------------------------------------------------------------------

  static const Color verifiedAccent = Color(0xFF009688);
  static const Color verifiedAccentLight = Color(0xFF009688);
  static Color verifiedAccentOf(BuildContext context) =>
      resolve(context, verifiedAccent, verifiedAccentLight);

  static const Color bondHigh = Colors.greenAccent;
  static const Color bondHighLight = Color(0xFF2E7D32);
  static Color bondHighOf(BuildContext context) =>
      resolve(context, bondHigh, bondHighLight);

  static const Color bondMid = Colors.blueAccent;
  static const Color bondMidLight = Color(0xFF1565C0);
  static Color bondMidOf(BuildContext context) =>
      resolve(context, bondMid, bondMidLight);

  static const Color bondLow = porchTerracotta;
  static const Color bondLowLight = porchTerracottaLight;
  static Color bondLowOf(BuildContext context) =>
      resolve(context, bondLow, bondLowLight);

  static const Color bondNeg = Colors.redAccent;
  static const Color bondNegLight = Color(0xFFC62828);
  static Color bondNegOf(BuildContext context) =>
      resolve(context, bondNeg, bondNegLight);

  static const Color trustHigh = Colors.tealAccent;
  static const Color trustHighLight = Color(0xFF00695C);
  static Color trustHighOf(BuildContext context) =>
      resolve(context, trustHigh, trustHighLight);

  /// Generic "primary accent" for forms, dialogs, Image Studio, and the
  /// avatar gallery (icons, badges, borders, primary buttons). Teal primary:
  /// this is now teal (was warm amber) so the ~30 files that key
  /// off it cool down in one place. It is a single const (not brightness-aware);
  /// on a teal button background use [onChaosAccent] for the foreground so
  /// text stays readable in dark mode.
  static const Color formMasterAccent = porchAmber;

  static const Color relationshipAccent = Colors.pinkAccent;
  static const Color relationshipAccentLight = Color(0xFFC2185B);
  static Color relationshipAccentOf(BuildContext context) =>
      resolve(context, relationshipAccent, relationshipAccentLight);

  static const Color emotionAccent = Colors.purpleAccent;
  static const Color emotionAccentLight = Color(0xFF7B1FA2);
  static Color emotionAccentOf(BuildContext context) =>
      resolve(context, emotionAccent, emotionAccentLight);

  static const Color optionalAccent = Colors.tealAccent;

  static const Color timeDayAccent = AppColors.porchAmber;
  static const Color timeDayAccentLight = Color(0xFFB45309);
  static Color timeDayAccentOf(BuildContext context) =>
      resolve(context, timeDayAccent, timeDayAccentLight);

  static const Color taskAccent = porchAmber;
  static const Color taskAccentLight = porchAmberLight;
  static Color taskAccentOf(BuildContext context) =>
      resolve(context, taskAccent, taskAccentLight);

  // ---------------------------------------------------------------------------
  // Warm-porch sidebar tokens (chat sidebar overhaul — one warm accent family
  // for section chrome, rose/ember for lust, one supporting cool tone for the
  // Journal/Memory cluster). Every former raw hex in the sidebar files maps to
  // exactly one token below; all have deliberate light variants.
  // ---------------------------------------------------------------------------

  /// 🎭 Character State section accent (soft pink).
  static const Color porchTerracotta = Color(0xFFFB8FAB);
  static const Color porchTerracottaLight = Color(0xFFB83A6E);
  static Color porchTerracottaOf(BuildContext context) =>
      resolve(context, porchTerracotta, porchTerracottaLight);

  /// 🎲 Story Tools section accent (sky blue).
  static const Color porchHoney = Color(0xFF7DD3FC);
  static const Color porchHoneyLight = Color(0xFF1D6FB8);
  static Color porchHoneyOf(BuildContext context) =>
      resolve(context, porchHoney, porchHoneyLight);

  /// Generic primary accent for buttons/badges — teal (was warm amber).
  static const Color porchAmber = Color(0xFF2DD4BF);
  static const Color porchAmberLight = Color(0xFF0E7A6D);
  static Color porchAmberOf(BuildContext context) =>
      resolve(context, porchAmber, porchAmberLight);

  /// 📖 Journal & Memory section accent — mint teal.
  static const Color journalAccent = Color(0xFF5EEAD4);
  static const Color journalAccentLight = Color(0xFF0E7A6D);
  static Color journalAccentOf(BuildContext context) =>
      resolve(context, journalAccent, journalAccentLight);

  /// Lust bar / spicy toggles / NSFW headers (pink).
  static const Color lustAccent = Color(0xFFF472B6);
  static const Color lustAccentLight = Color(0xFFDB2777);
  static Color lustAccentOf(BuildContext context) =>
      resolve(context, lustAccent, lustAccentLight);

  /// Lust "fire" state (arousal tier >= 6).
  static const Color lustDeep = Color(0xFFEC4899);
  static const Color lustDeepLight = Color(0xFF9D174D);
  static Color lustDeepOf(BuildContext context) =>
      resolve(context, lustDeep, lustDeepLight);

  /// Negative arousal / refractory chill.
  static const Color frostAccent = Color(0xFF38BDF8);
  static const Color frostAccentLight = Color(0xFF2563EB);
  static Color frostAccentOf(BuildContext context) =>
      resolve(context, frostAccent, frostAccentLight);

  /// Chaos Mode accent (pink).
  static const Color chaosAccent = Color(0xFFF9A8D4);
  static const Color chaosAccentLight = Color(0xFFC2437F);
  static Color chaosAccentOf(BuildContext context) =>
      resolve(context, chaosAccent, chaosAccentLight);

  /// Spin-button gradient second stop.
  static const Color chaosAccentDim = Color(0xFFF472B6);
  static const Color chaosAccentDimLight = Color(0xFFDB2777);
  static Color chaosAccentDimOf(BuildContext context) =>
      resolve(context, chaosAccentDim, chaosAccentDimLight);

  /// Text/icon color on the chaos accent button (both modes).
  static const Color onChaosAccent = Color(0xFF032520);

  /// Chaos pressure-lerp start (calm teal) and end (hot pink).
  static const Color chaosCalm = Color(0xFF2DD4BF);
  static const Color chaosCalmLight = Color(0xFF0E7A6D);
  static Color chaosCalmOf(BuildContext context) =>
      resolve(context, chaosCalm, chaosCalmLight);
  static const Color chaosHot = Color(0xFFF472B6);
  static const Color chaosHotLight = Color(0xFFDB2777);
  static Color chaosHotOf(BuildContext context) =>
      resolve(context, chaosHot, chaosHotLight);

  /// Positive trust bar/icon accent.
  static const Color trustAccent = Color(0xFF5EEAD4);
  static const Color trustAccentLight = Color(0xFF0E7A6D);
  static Color trustAccentOf(BuildContext context) =>
      resolve(context, trustAccent, trustAccentLight);

  /// Negative trust/bond, critical needs, destructive hints.
  static const Color negativeAccent = Color(0xFFEF5350);
  static const Color negativeAccentLight = Color(0xFFD32F2F);
  static Color negativeAccentOf(BuildContext context) =>
      resolve(context, negativeAccent, negativeAccentLight);

  /// Fixation chip/banner purple (engine identity).
  static const Color fixationAccent = Color(0xFFE040FB);
  static const Color fixationAccentLight = Color(0xFF7B1FA2);
  static Color fixationAccentOf(BuildContext context) =>
      resolve(context, fixationAccent, fixationAccentLight);

  /// Inset wells (settings panels, sunken sub-surfaces). Light = mint paper.
  static const Color sunkenSurface = Color(0xFF03201B);
  static const Color sunkenSurfaceLight = Color(0xFFE9F4F1);
  static Color sunkenSurfaceOf(BuildContext context) =>
      resolveOled(context, sunkenSurface, sunkenSurfaceLight, oledBackground);

  /// Read-only text wells (deepest inset, e.g. evolution "original" text).
  static const Color deepWell = Color(0xFF03201B);
  static const Color deepWellLight = Color(0xFFEEF7F4);
  static Color deepWellOf(BuildContext context) =>
      resolveOled(context, deepWell, deepWellLight, oledBackground);

  // ── KoboldCpp presets and the local model card (approved sketch,
  // 2026-10-04): slate text, an inset panel, and the parts of the preset
  // editor's memory bar (kcpps_memory_bar.dart; the old one in Settings →
  // Hardware & GPU is gone).
  static const Color insetPanel = Color(0xFF0B3A33);
  static const Color insetPanelLight = Color(0xFFE7F3F0);
  static Color insetPanelOf(BuildContext context) =>
      resolveOled(context, insetPanel, insetPanelLight, oledSurface);
  static const Color slateInk = Color(0xFFF3F4F6);
  static const Color slateInkLight = Color(0xFF1F2937);
  static Color slateInkOf(BuildContext context) =>
      resolve(context, slateInk, slateInkLight);
  static const Color slateMuted = Color(0xFFCBD5E1);
  static const Color slateMutedLight = Color(0xFF475569);
  static Color slateMutedOf(BuildContext context) =>
      resolve(context, slateMuted, slateMutedLight);
  static const Color slateFaint = Color(0xFF94A3B8);
  static const Color slateFaintLight = Color(0xFF64748B);
  static Color slateFaintOf(BuildContext context) =>
      resolve(context, slateFaint, slateFaintLight);

  /// A hairline at [alpha]: light on dark, dark on light.
  static Color hairlineOf(BuildContext context, double alpha) => resolve(
    context,
    Colors.white.withValues(alpha: alpha),
    Colors.black.withValues(alpha: alpha * 0.9),
  );
  static const Color alertRed = Color(0xFFF87171);
  static const Color alertRedLight = Color(0xFFB91C1C);
  static Color alertRedOf(BuildContext context) =>
      resolve(context, alertRed, alertRedLight);

  /// Text on solid [porchAmber] and on solid [journalAccent].
  static const Color onPorchAmber = Color(0xFF241505);
  static const Color onJournalAccent = Color(0xFF062B27);
  static const Color loadExperts = Color(0xFFA9612B);
  static const Color onLoadExperts = Color(0xFFFFF7EE);
  static const Color loadWorking = Color(0xFF64748B);
  static const Color loadEngine = Color(0xFF94A3B8);
  static const Color onLoadEngine = Color(0xFF0F172A);
  static const Color loadOver = Color(0xFF7F1D1D);
  static const Color loadOverStripe = Color(0xFF991B1B);
  static const Color onLoadOver = Color(0xFFFEE2E2);
  static const Color loadUnusedStripe = Color(0xFF334155);
  static const Color loadUnusedStripeLight = Color(0xFFD4CFC6);
  static Color loadUnusedStripeOf(BuildContext context) =>
      resolve(context, loadUnusedStripe, loadUnusedStripeLight);
}
