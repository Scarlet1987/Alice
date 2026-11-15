// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// FAQ shared widgets: the draft tag, guide group titles, the
// expandable question, and the suggestion-box field. The screen file
// stays under the 500-line ratchet by keeping these here.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/ui/alice/v9/alice_v9_faq_content.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// The draft tag on the guide: the questions are anticipated, not
/// asked by anyone yet, and the wording is Elaina's to approve.
class FaqDraftTag extends StatelessWidget {
  const FaqDraftTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.aliceMint.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Draft — for approval',
        style: TextStyle(fontSize: 13, color: AppColors.aliceMint),
      ),
    );
  }
}

class FaqGuideGroupTitle extends StatelessWidget {
  const FaqGuideGroupTitle(this.title, this.subtitle, {super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cormorant Garamond',
            fontFamilyFallback: ['Georgia'],
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.aliceMint,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.aliceInkSoft),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// One pre-answered question: the question always shows, the answer
/// opens on tap. The first item of a group starts open.
class FaqItem extends StatefulWidget {
  const FaqItem({required this.qa, this.open = false, super.key});

  final FaqQA qa;
  final bool open;

  @override
  State<FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<FaqItem> {
  late bool _open = widget.open;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.qa.question,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.aliceSage,
                    ),
                  ),
                ),
                Text(
                  _open ? '−' : '+',
                  style: const TextStyle(
                    fontSize: 20,
                    color: AppColors.aliceMint,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              widget.qa.answer,
              style: const TextStyle(fontSize: 15, color: AppColors.aliceLede),
            ),
          ),
        Container(
          height: 1,
          color: AppColors.aliceLine.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

/// One suggestion-box field: label, the question it asks, the hint,
/// and the box itself.
class FaqTextField extends StatelessWidget {
  const FaqTextField({
    required this.field,
    required this.controller,
    this.maxLines = 1,
    super.key,
  });

  final FaqField field;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.aliceSage,
          ),
        ),
        Text(
          field.question,
          style: const TextStyle(fontSize: 14, color: AppColors.aliceLede),
        ),
        Text(
          field.hint,
          style: const TextStyle(fontSize: 13, color: AppColors.aliceInkSoft),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: field.placeholder,
            hintStyle: TextStyle(
              color: AppColors.aliceSage.withValues(alpha: 0.55),
            ),
            filled: true,
            fillColor: AppColors.aliceSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.aliceLine),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.aliceLine),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.aliceGreen),
            ),
            isDense: true,
          ),
          style: const TextStyle(color: AppColors.aliceSage),
        ),
      ],
    );
  }
}
