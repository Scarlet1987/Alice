// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// The running file, on screen: the same markdown the file holds,
// grouped by category with the jump mark on the batch. Entries are
// removed here; the file is downloaded or copied for upload. Nothing
// is sent anywhere from this screen.

import 'package:flutter/material.dart';

import 'package:front_porch_ai/services/feedback_file_service.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_faq_content.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';

/// The running-file card: jump mark, done-list, grouped entries, and
/// the Download / Copy / fresh-file actions. Presentational — the
/// screen owns the file and all the callbacks.
class AliceFaqFileView extends StatelessWidget {
  const AliceFaqFileView({
    super.key,
    required this.file,
    required this.loadError,
    required this.mark,
    required this.onMarkChanged,
    required this.onRemove,
    required this.onDownload,
    required this.onCopy,
    required this.onFreshFile,
    this.note,
  });

  final FeedbackFile? file;
  final String? loadError;
  final FeedbackJumpMark mark;
  final ValueChanged<FeedbackJumpMark> onMarkChanged;
  final ValueChanged<FeedbackEntry> onRemove;
  final VoidCallback onDownload;
  final VoidCallback onCopy;
  final VoidCallback onFreshFile;
  final String? note;

  static const _body = TextStyle(fontSize: 15, color: AppColors.aliceSage);

  @override
  Widget build(BuildContext context) {
    final data = file;
    return V9Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const V9Heading('The running file'),
          const SizedBox(height: 8),
          const V9Muted(
            'One file, collecting until it\'s uploaded and worked '
            'through. This is exactly what the uploaded file looks like.',
          ),
          const SizedBox(height: 16),
          if (loadError != null) ...[
            Text(
              loadError!,
              style: _body.copyWith(color: AppColors.aliceMint),
            ),
            const SizedBox(height: 12),
          ],
          if (data == null)
            const V9Muted('Loading the file…')
          else ...[
            Text(
              'File opened ${FeedbackFile.formatDate(data.fileOpened)} · '
              '${data.entries.length} '
              '${data.entries.length == 1 ? 'entry' : 'entries'} · '
              'grouped by category, six fields each',
              style: _body.copyWith(color: AppColors.aliceInkSoft),
            ),
            const SizedBox(height: 16),
            const Text(
              'Jump mark for this batch — written into the file, so it\'s '
              'certain',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.aliceSage,
              ),
            ),
            const SizedBox(height: 10),
            for (final option in FeedbackJumpMark.values) ...[
              SizedBox(
                height: 44,
                child: V9Button(
                  label: option.label,
                  ghost: mark != option,
                  small: true,
                  fillWidth: true,
                  onPressed: () => onMarkChanged(option),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (mark == FeedbackJumpMark.outOfBeta) ...[
              const SizedBox(height: 6),
              const Text(
                'The out-of-beta test',
                style: TextStyle(
                  fontFamily: 'Cormorant Garamond',
                  fontFamilyFallback: ['Georgia'],
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.aliceMint,
                ),
              ),
              const SizedBox(height: 8),
              for (final item in kFaqDoneList)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('•  $item', style: _body),
                ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            if (data.entries.isEmpty)
              const V9Muted(
                'Nothing collected yet. The first entry added in the '
                'suggestion box starts the file.',
              )
            else
              _entries(data),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                V9Button(
                  label: 'Download the file',
                  small: true,
                  onPressed: onDownload,
                ),
                V9Button(
                  label: 'Copy the file',
                  small: true,
                  ghost: true,
                  onPressed: onCopy,
                ),
                V9Button(
                  label: 'Start a fresh file',
                  small: true,
                  ghost: true,
                  onPressed: onFreshFile,
                ),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: 12),
              Text(note!, style: _body.copyWith(color: AppColors.aliceMint)),
            ],
            const SizedBox(height: 16),
            const V9Muted(
              'Feedback sent here is collected into the running file '
              'only — download it and upload it when you\'re ready to '
              'work through the changes.',
            ),
          ],
        ],
      ),
    );
  }

  /// Entries grouped by category in file order, numbered across the
  /// whole file the way the markdown numbers them.
  Widget _entries(FeedbackFile data) {
    var number = 0;
    final groups = <Widget>[];
    for (final category in FeedbackFile.categories) {
      final inCategory = data.entries
          .where((entry) => entry.category == category)
          .toList();
      if (inCategory.isEmpty) continue;
      groups.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            '$category — ${inCategory.length} '
            '${inCategory.length == 1 ? 'entry' : 'entries'}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.aliceMint,
            ),
          ),
        ),
      );
      for (final entry in inCategory) {
        number++;
        groups.add(_entry(number, entry));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: groups,
    );
  }

  Widget _entry(int number, FeedbackEntry entry) {
    String field(String value) =>
        value.trim().isEmpty ? 'not given' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. [${entry.kind.label}] ${field(entry.what)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.aliceSage,
            ),
          ),
          const SizedBox(height: 4),
          for (final line in [
            'Who: ${field(entry.who)}',
            'What: ${field(entry.what)}',
            'When: ${field(entry.when)}',
            'Where: ${field(entry.where)}',
            'Why: ${field(entry.why)}',
            'How: ${field(entry.how)}',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(line, style: _body),
            ),
          const SizedBox(height: 8),
          V9Button(
            label: 'Remove this entry',
            small: true,
            ghost: true,
            onPressed: () => onRemove(entry),
          ),
        ],
      ),
    );
  }
}
