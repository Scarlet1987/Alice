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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/models/models.dart';
import 'package:front_porch_ai/services/services.dart';
import 'package:front_porch_ai/ui/theme/theme.dart';
import 'package:front_porch_ai/ui/widgets/widgets.dart';
import 'external_image_widget.dart';

/// Applies a font family to a base TextStyle. Every family the switch names
/// is bundled natively (see the fonts section of pubspec.yaml); system fonts
/// are applied as named fontFamily directly.
TextStyle _applyChatFont(String? fontFamily, TextStyle baseStyle) {
  if (fontFamily == null || fontFamily.isEmpty) return baseStyle;

  switch (fontFamily) {
    case 'Roboto':
      return baseStyle.copyWith(fontFamily: 'Roboto');
    case 'Open Sans':
      return baseStyle.copyWith(fontFamily: 'OpenSans');
    case 'Lato':
      return baseStyle.copyWith(fontFamily: 'Lato');
    case 'Source Sans 3':
      return baseStyle.copyWith(fontFamily: 'SourceSans3');
    case 'Nunito':
      return baseStyle.copyWith(fontFamily: 'Nunito');
    case 'Poppins':
      return baseStyle.copyWith(fontFamily: 'Poppins');
    case 'Montserrat':
      return baseStyle.copyWith(fontFamily: 'Montserrat');
    case 'Raleway':
      return baseStyle.copyWith(fontFamily: 'Raleway');
    case 'Work Sans':
      return baseStyle.copyWith(fontFamily: 'WorkSans');
    case 'DM Sans':
      return baseStyle.copyWith(fontFamily: 'DMSans');
    case 'Quicksand':
      return baseStyle.copyWith(fontFamily: 'Quicksand');
    case 'Rubik':
      return baseStyle.copyWith(fontFamily: 'Rubik');
    case 'Karla':
      return baseStyle.copyWith(fontFamily: 'Karla');
    case 'Merriweather':
      return baseStyle.copyWith(fontFamily: 'Merriweather');
    case 'Playfair Display':
      return baseStyle.copyWith(fontFamily: 'PlayfairDisplay');
    case 'Roboto Mono':
      return baseStyle.copyWith(fontFamily: 'RobotoMono');
    case 'Fira Code':
      return baseStyle.copyWith(fontFamily: 'FiraCode');
    case 'Source Code Pro':
      return baseStyle.copyWith(fontFamily: 'SourceCodePro');
    // System fonts — apply as named fontFamily directly
    case 'serif':
      return baseStyle.copyWith(fontFamily: 'Times New Roman');
    case 'sans-serif':
      return baseStyle.copyWith(fontFamily: 'Arial');
    case 'monospace':
      return baseStyle.copyWith(fontFamily: 'Courier New');
    default:
      return baseStyle.copyWith(fontFamily: fontFamily);
  }
}

final _markdownImageRegex = RegExp(r'!\[([^\]]*)\]\((https?://[^)]+)\)');

/// Styled chat message with quote/action coloring and external image support.
///
/// Stateful purely for PARSE CACHING: during streaming the whole visible
/// message list rebuilds many times a second, and re-running the markdown
/// scan + dialogue/action tokenizer + font-style resolution for
/// every unchanged message was the dominant UI-thread cost. Parse results
/// are cached keyed on the source text (identical() fast path — unchanged
/// messages keep the same string object; only the streaming bubble re-parses)
/// and the three resolved styles are cached on their inputs. Widgets are
/// still constructed fresh each build (cheap), so callbacks never go stale.
class StyledChatMessage extends StatefulWidget {
  final String text;
  final bool isUser;
  final bool? externalImagesAllowed;
  final Future<bool> Function()? onRequestImagePermission;
  final CharacterCard? character;
  final ChatThemePreset? themePreset;
  final ChatThemeOverrides? themeOverrides;

  const StyledChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.externalImagesAllowed,
    this.onRequestImagePermission,
    this.character,
    this.themePreset,
    this.themeOverrides,
  });

  @override
  State<StyledChatMessage> createState() => _StyledChatMessageState();
}

class _StyledChatMessageState extends State<StyledChatMessage> {
  // Text-derived caches (invalidated when the source string changes).
  String? _parseSource;
  List<RegExpMatch>? _imageMatches;
  final Map<
    String,
    List<({int start, int end, String matchText, StyledTokenType type})>
  >
  _tokenCache = {};

  // Style caches (invalidated when any styling input changes).
  (String?, Color, Color, Color)? _styleKey;
  TextStyle? _plainStyle;
  TextStyle? _dialogueStyle;
  TextStyle? _actionStyle;
  TextStyle? _rootStyle;

  List<({int start, int end, String matchText, StyledTokenType type})>
  _tokensFor(String segment) =>
      _tokenCache.putIfAbsent(segment, () => tokenizeChat(segment).toList());

  void _refreshStyles(StorageService storageService) {
    final character = widget.character;
    final fontFamily = storageService.uiSettings.getChatFontFamily(
      character,
      themePreset: widget.themePreset,
      themeOverrides: widget.themeOverrides,
    );
    final textColor = widget.isUser
        ? storageService.uiSettings.getUserTextColor(
            character,
            themePreset: widget.themePreset,
            themeOverrides: widget.themeOverrides,
          )
        : storageService.uiSettings.getAiTextColor(
            character,
            themePreset: widget.themePreset,
            themeOverrides: widget.themeOverrides,
          );
    final dialogueColor = storageService.uiSettings.getDialogueColor(
      character,
      themePreset: widget.themePreset,
      themeOverrides: widget.themeOverrides,
    );
    final actionColor = storageService.uiSettings.getActionColor(
      character,
      themePreset: widget.themePreset,
      themeOverrides: widget.themeOverrides,
    );
    final key = (fontFamily, textColor, dialogueColor, actionColor);
    if (key == _styleKey) return;
    _styleKey = key;
    // fontSize is the shared reading base. The RichText/Text below get
    // StorageService.textScale as textScaler — do not also bake it here.
    _plainStyle = _applyChatFont(
      fontFamily,
      readingSurfaceStyle(color: textColor),
    );
    _dialogueStyle = _applyChatFont(
      fontFamily,
      readingSurfaceStyle(color: dialogueColor, fontWeight: FontWeight.w500),
    );
    _actionStyle = _applyChatFont(
      fontFamily,
      readingSurfaceStyle(color: actionColor),
    );
    _rootStyle = _applyChatFont(
      fontFamily,
      readingSurfaceStyle(color: textColor, height: 1.4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context);
    final text = widget.text;
    _refreshStyles(storageService);
    // Reading Size is this pref. Do not trust ambient MediaQuery — chrome
    // may scale from it while the transcript sits at 1.0 (or the reverse).
    final readingScaler = readingTextScaler(
      storageService.uiSettings.textScale,
    );

    // Check for markdown images (cached per source text).
    if (!identical(text, _parseSource)) {
      _parseSource = text;
      _tokenCache.clear();
      _imageMatches = _markdownImageRegex.allMatches(text).toList();
    }
    final imageMatches = _imageMatches!;
    if (imageMatches.isEmpty) {
      // No images — use existing fast path
      return _buildStyledText(text, readingScaler);
    }

    // Split text into segments: [text, image, text, image, text]
    final widgets = <Widget>[];
    int lastEnd = 0;

    for (final match in imageMatches) {
      // Text before this image
      if (match.start > lastEnd) {
        final textBefore = text.substring(lastEnd, match.start).trim();
        if (textBefore.isNotEmpty) {
          widgets.add(_buildStyledText(textBefore, readingScaler));
        }
      }

      final altText = match.group(1) ?? '';
      final imageUrl = match.group(2)!;

      // Image placeholder or loaded image
      widgets.add(
        ExternalImageWidget(
          url: imageUrl,
          altText: altText,
          allowed: widget.externalImagesAllowed,
          onRequestPermission: widget.onRequestImagePermission,
        ),
      );

      lastEnd = match.end;
    }

    // Remaining text after last image
    if (lastEnd < text.length) {
      final textAfter = text.substring(lastEnd).trim();
      if (textAfter.isNotEmpty) {
        widgets.add(_buildStyledText(textAfter, readingScaler));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildStyledText(String segment, TextScaler readingScaler) {
    final tokens = _tokensFor(segment);

    final spans = <TextSpan>[];
    int lastEnd = 0;
    for (final t in tokens) {
      if (t.start > lastEnd) {
        spans.add(
          TextSpan(
            text: segment.substring(lastEnd, t.start),
            style: _plainStyle,
          ),
        );
      }
      spans.add(
        TextSpan(
          text: t.matchText,
          style: t.type == StyledTokenType.dialogue
              ? _dialogueStyle
              : _actionStyle,
        ),
      );
      lastEnd = t.end;
    }
    if (lastEnd < segment.length) {
      spans.add(TextSpan(text: segment.substring(lastEnd), style: _plainStyle));
    }

    if (spans.isEmpty) {
      return Text(segment, style: _rootStyle, textScaler: readingScaler);
    }

    // Text.rich (not raw RichText) so find.text still sees the words
    // without a nested SelectionArea. textScaler is Reading Size.
    return Text.rich(
      TextSpan(style: _rootStyle, children: spans),
      textScaler: readingScaler,
    );
  }
}
