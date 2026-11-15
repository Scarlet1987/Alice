// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice FAQ, from the approved preview (Space alice-faq-feedback-preview,
// Elaina 2026-11-14: "that is perfect lets do this as the faq feature"):
// the policy questions, the draft guide in its two audience groups, and
// the suggestion box feeding the one running file. Pushed as a route
// from Home's Jump To, like the Worlds screen — it is not a fifth shell
// page. The screen owns its own scroll view because it lives outside
// the shell; the shell's one-scroll rule covers shell pages only.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:front_porch_ai/services/feedback_file_service.dart';
import 'package:front_porch_ai/services/storage_service.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_faq_content.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_faq_file.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_faq_widgets.dart';
import 'package:front_porch_ai/ui/alice/v9/alice_v9_widgets.dart';
import 'package:front_porch_ai/ui/theme/app_colors.dart';
import 'package:front_porch_ai/ui/widgets/guarded_picker.dart';
import 'package:front_porch_ai/ui/widgets/warm_dialog.dart';
import 'package:front_porch_ai/utils/picker_prefs.dart';

class AliceFaqScreen extends StatefulWidget {
  const AliceFaqScreen({super.key, this.initialFile, this.service});

  /// A preloaded file, for tests: when given, the screen uses it
  /// directly instead of loading the file from disk. In production
  /// this is always null and the screen loads the file itself.
  final FeedbackFile? initialFile;

  /// The file service, for tests: when given, the screen uses it
  /// instead of building one from StorageService.
  final FeedbackFileService? service;

  @override
  State<AliceFaqScreen> createState() => _AliceFaqScreenState();
}

class _AliceFaqScreenState extends State<AliceFaqScreen> {
  late final FeedbackFileService _service;
  FeedbackFile? _file;
  String? _loadError;

  FeedbackKind _kind = FeedbackKind.request;
  String _category = FeedbackFile.categories.first;
  FeedbackJumpMark _mark = FeedbackJumpMark.versionChange;

  final Map<String, TextEditingController> _fields = {
    for (final field in kFaqFields) field.id: TextEditingController(),
  };

  String? _formError;
  String? _formNote;
  String? _fileNote;

  @override
  void initState() {
    super.initState();
    _service = widget.service ??
        FeedbackFileService(
          context.read<StorageService>().feedbackDir,
        );
    final initial = widget.initialFile;
    if (initial != null) {
      _file = initial;
      _mark = initial.jumpMark;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final loaded = await _service.load();
      if (!mounted) return;
      setState(() {
        _file = loaded;
        _mark = loaded.jumpMark;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _file = FeedbackFile(fileOpened: DateTime.now());
        _loadError =
            'The feedback file could not be read — new entries will '
            'start a fresh one.';
      });
    }
  }

  Future<void> _save() async {
    final data = _file;
    if (data == null) return;
    data.jumpMark = _mark;
    try {
      await _service.save(data);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fileNote = 'The feedback file could not be saved.';
      });
    }
  }

  String _text(String id) => _fields[id]!.text.trim();

  Future<void> _submit() async {
    if (_text('what').isEmpty) {
      setState(() {
        _formError =
            'The file needs the What — everything else can be filled in '
            'as best you can.';
        _formNote = null;
      });
      return;
    }
    final data = _file;
    if (data == null) return;
    data.entries.add(
      FeedbackEntry(
        kind: _kind,
        category: _category,
        who: _text('who'),
        what: _text('what'),
        when: _text('when'),
        where: _text('where'),
        why: _text('why'),
        how: _text('how'),
      ),
    );
    for (final controller in _fields.values) {
      controller.clear();
    }
    setState(() {
      _formError = null;
      _formNote = 'Added — it\'s in the file, under its category.';
    });
    await _save();
  }

  Future<void> _removeEntry(FeedbackEntry entry) async {
    _file?.entries.remove(entry);
    setState(() {});
    await _save();
  }

  Future<void> _setMark(FeedbackJumpMark mark) async {
    setState(() => _mark = mark);
    await _save();
  }

  Future<void> _copy() async {
    final data = _file;
    if (data == null) return;
    await Clipboard.setData(
      ClipboardData(text: data.renderMarkdown()),
    );
    if (!mounted) return;
    setState(() => _fileNote = 'Copied — ready to paste or send.');
  }

  Future<void> _download() async {
    final data = _file;
    if (data == null) return;
    await GuardedPicker.saveFile(
      context,
      category: PickerPrefs.catExport,
      bytes: utf8.encode(data.renderMarkdown()),
      dialogTitle: 'Save the feedback file',
      fileName: FeedbackFile.fileName,
      type: FileType.custom,
      allowedExtensions: const ['md'],
    );
  }

  Future<void> _freshFile() async {
    final confirmed = await showWarmDialog<bool>(
      context,
      title: 'Start a fresh file?',
      content: const Text(
        'This clears every entry in the running file and starts a new '
        'one. Download or copy the file first if you want to keep it.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep it'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Start fresh'),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;
    await _service.clear();
    setState(() {
      _file = FeedbackFile(fileOpened: DateTime.now());
      _mark = FeedbackJumpMark.versionChange;
      _fileNote = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.aliceHeroDeep,
            AppColors.aliceInk,
            AppColors.aliceForest,
          ],
        ),
      ),
      // One Material ancestor for the whole pushed page: without it,
      // plain text inherits Flutter's fallback style (red, monospace,
      // underlined) instead of the theme, and InkWells throw — the
      // same lesson as the Worlds screen.
      child: Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 18),
                  _buildPolicyCard(),
                  const SizedBox(height: 18),
                  _buildGuideCard(),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final form = _buildSuggestionBox();
                      final fileView = AliceFaqFileView(
                        file: _file,
                        loadError: _loadError,
                        mark: _mark,
                        onMarkChanged: _setMark,
                        onRemove: _removeEntry,
                        onDownload: _download,
                        onCopy: _copy,
                        onFreshFile: _freshFile,
                        note: _fileNote,
                      );
                      if (constraints.maxWidth < 900) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            form,
                            const SizedBox(height: 18),
                            fileView,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: form),
                          const SizedBox(width: 18),
                          Expanded(child: fileView),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        V9Button(
          label: 'Back',
          ghost: true,
          small: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 16),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Questions, complaints & '),
              TextSpan(
                text: 'requests',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            style: TextStyle(
              fontFamily: 'Cormorant Garamond',
              fontFamilyFallback: ['Georgia'],
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: AppColors.aliceMint,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Everything sent through the suggestion box below lands in one '
          'running file, sorted as it arrives. When the file is '
          'uploaded, the changes get worked through together — and Alice '
          'moves in large jumps shaped by the categories the feedback '
          'came in under.',
          style: TextStyle(fontSize: 16, color: AppColors.aliceLede),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.aliceMint.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(999),
            color: AppColors.aliceMint.withValues(alpha: 0.08),
          ),
          child: const Text(
            'Alice is free while it\'s in beta.',
            style: TextStyle(fontSize: 14, color: AppColors.aliceMint),
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyCard() {
    return V9Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const V9Heading('Frequently asked questions'),
          const SizedBox(height: 8),
          for (var i = 0; i < kFaqPolicy.length; i++)
            FaqItem(qa: kFaqPolicy[i], open: i == 0),
        ],
      ),
    );
  }

  Widget _buildGuideCard() {
    return V9Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Expanded(child: V9Heading('New here? Start with these')),
              SizedBox(width: 12),
              FaqDraftTag(),
            ],
          ),
          const SizedBox(height: 8),
          const V9Muted(
            'Two kinds of people land here. Folks coming from a much '
            'simpler app need the basics, answered plainly. Folks coming '
            'from SillyTavern go looking for the detailed things that '
            'program has — character cards, presets, lorebooks — and want '
            'to know where each one lives in Alice. Both sets are below, '
            'anticipated from what Alice does — nobody has sent them '
            'through the suggestion box yet, and the wording is Elaina\'s '
            'to approve or change.',
          ),
          const SizedBox(height: 16),
          const FaqGuideGroupTitle(
            'Start with the basics',
            'New to this kind of app? These are the questions an FAQ can '
                'answer outright.',
          ),
          for (var i = 0; i < kFaqBasics.length; i++)
            FaqItem(qa: kFaqBasics[i], open: i == 0),
          const SizedBox(height: 16),
          const FaqGuideGroupTitle(
            'Coming from SillyTavern',
            'The common things that program has, and where each one lives '
                'in Alice.',
          ),
          for (final qa in kFaqSillyTavern) FaqItem(qa: qa),
        ],
      ),
    );
  }

  Widget _buildSuggestionBox() {
    return V9Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const V9Heading('The suggestion box'),
          const SizedBox(height: 8),
          const V9Muted(
            'Six questions, the same six every time — so nothing arrives '
            'half-told.',
          ),
          const SizedBox(height: 16),
          const Text(
            'This is a',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.aliceSage,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final kind in FeedbackKind.values) ...[
                V9Button(
                  label: kind.label,
                  small: true,
                  ghost: _kind != kind,
                  onPressed: () => setState(() => _kind = kind),
                ),
                const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 16),
          V9SlotDropdown(
            label: 'Category',
            items: FeedbackFile.categories,
            value: _category,
            onChanged: (next) {
              if (next != null) setState(() => _category = next);
            },
            emptyHint: '—',
          ),
          const SizedBox(height: 4),
          const V9Muted('the file groups by this'),
          const SizedBox(height: 16),
          for (final field in kFaqFields) ...[
            FaqTextField(
              field: field,
              controller: _fields[field.id]!,
              maxLines: field.id == 'what' || field.id == 'how' ? 3 : 1,
            ),
            const SizedBox(height: 14),
          ],
          if (_formError != null) ...[
            Text(
              _formError!,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.aliceMint,
              ),
            ),
            const SizedBox(height: 10),
          ],
          V9Button(
            label: 'Add it to the file',
            onPressed: _submit,
          ),
          if (_formNote != null) ...[
            const SizedBox(height: 12),
            Text(
              _formNote!,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.aliceMint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
