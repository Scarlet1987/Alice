// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice v9 identity rows (combined preview v9): gender identity and
// pronouns, male / female / non-Binary / custom and he/him / she/her /
// they/them / custom. Tapping custom opens a text field to type your own
// gender identity / pronoun identity. That typed value is saved with the
// pick — it is the point of the custom button, not a label.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// Gender identity options, in the preview's order and spelling.
const List<String> kV9GenderOptions = [
  'male',
  'female',
  'non-Binary',
  'custom',
];

/// Pronoun options, in the preview's order and spelling.
const List<String> kV9PronounOptions = [
  'he/him',
  'she/her',
  'they/them',
  'custom',
];

/// One identity pick: a button choice plus, when the choice is custom,
/// the typed value. [resolved] is what is saved and shown everywhere:
/// the typed value when custom was picked and typed, else the pick.
class V9Identity {
  String pick;
  String custom;

  V9Identity({this.pick = 'male', this.custom = ''});

  String get resolved {
    if (pick == 'custom' && custom.trim().isNotEmpty) {
      return custom.trim();
    }
    return pick;
  }

  bool get isCustom => pick == 'custom';

  Map<String, String> toJson() => {'pick': pick, 'custom': custom};

  factory V9Identity.fromJson(Map<String, dynamic>? json) {
    if (json == null) return V9Identity();
    return V9Identity(
      pick: json['pick'] as String? ?? 'male',
      custom: json['custom'] as String? ?? '',
    );
  }

  V9Identity copy() => V9Identity(pick: pick, custom: custom);
}

/// One gender-identity or pronouns row: option buttons in a wrap, and a
/// text field that appears only when custom is picked. The parent owns
/// the [V9Identity] and persists every change; [saved] tells the row the
/// typed value has been written, so it can show "Saved." under the field.
/// Stateful so the custom field keeps its controller (and focus) while
/// the parent rebuilds on every keystroke.
class V9IdentityRow extends StatefulWidget {
  final String label;
  final List<String> options;
  final String customHint;
  final V9Identity value;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onCustomChanged;
  final bool saved;

  const V9IdentityRow({
    super.key,
    required this.label,
    required this.options,
    required this.customHint,
    required this.value,
    required this.onPick,
    required this.onCustomChanged,
    this.saved = false,
  });

  @override
  State<V9IdentityRow> createState() => _V9IdentityRowState();
}

class _V9IdentityRowState extends State<V9IdentityRow> {
  late final TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController(text: widget.value.custom);
  }

  @override
  void didUpdateWidget(V9IdentityRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // An outside change (restore from storage) replaces the text; a
    // keystroke already updated it through onChanged, so never fight it.
    if (_customController.text != widget.value.custom &&
        widget.value.custom != oldWidget.value.custom) {
      _customController.text = widget.value.custom;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in widget.options)
              _OptionButton(
                label: option,
                selected: widget.value.pick == option,
                onTap: () => widget.onPick(option),
              ),
          ],
        ),
        if (widget.value.isCustom) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _customController,
            onChanged: widget.onCustomChanged,
            decoration: InputDecoration(
              hintText: widget.customHint,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.alicePale,
            ),
          ),
          if (widget.saved && widget.value.custom.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Saved.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.aliceGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// One option button: solid green, white words; the picked one inverts
/// to white with green words and a green outline (preview .sel style).
class _OptionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.pureWhite
              : AppColors.aliceGreen,
          border: Border.all(
            color: AppColors.aliceGreen,
            width: selected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.pureBlack.withValues(alpha: 0.25),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: selected
                ? AppColors.aliceGreen
                : AppColors.pureWhite,
            fontFamily: 'Georgia',
          ),
        ),
      ),
    );
  }
}
