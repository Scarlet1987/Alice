// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// The running feedback file: one markdown file under the user-visible
// feedback folder that keeps collecting every complaint and request
// from the FAQ suggestion box, heavily organized — entries grouped by
// category, each one carrying who, what, when, where, why, and how.
// The file is what gets uploaded and worked through, category by
// category; the app only produces it (download / copy) and never sends
// it anywhere itself.

import 'dart:io';

import 'package:path/path.dart' as path;

/// Request or complaint — the suggestion box asks which one it is.
enum FeedbackKind {
  request,
  complaint;

  String get label => switch (this) {
    FeedbackKind.request => 'Request',
    FeedbackKind.complaint => 'Complaint',
  };
}

/// The jump mark for a batch: a version change (still beta, still
/// free) or the out-of-beta jump to v2.0. Written into the file, so it
/// is certain, not a judgment call.
enum FeedbackJumpMark {
  versionChange,
  outOfBeta;

  String get label => switch (this) {
    FeedbackJumpMark.versionChange =>
      'Version change — still beta, still free',
    FeedbackJumpMark.outOfBeta => 'Out of beta — the v2.0 jump',
  };

  String get fileLine => switch (this) {
    FeedbackJumpMark.versionChange =>
      'Jump mark: VERSION CHANGE — still in beta, still free',
    FeedbackJumpMark.outOfBeta => 'Jump mark: OUT OF BETA — the v2.0 jump',
  };
}

/// One complaint or request, with the same six fields every time.
class FeedbackEntry {
  const FeedbackEntry({
    required this.kind,
    required this.category,
    required this.who,
    required this.what,
    required this.when,
    required this.where,
    required this.why,
    required this.how,
  });

  final FeedbackKind kind;
  final String category;
  final String who;
  final String what;
  final String when;
  final String where;
  final String why;
  final String how;
}

/// The running file itself: the entries in arrival order, the jump
/// mark for the batch, and the date the file was opened. Renders to
/// the markdown the user downloads, and parses that same markdown
/// back — the file on disk is the record, not a second copy of it.
class FeedbackFile {
  FeedbackFile({
    required this.fileOpened,
    this.jumpMark = FeedbackJumpMark.versionChange,
    List<FeedbackEntry>? entries,
  }) : entries = entries ?? [];

  static const fileName = 'alice-feedback-file.md';

  /// Categories in file order. Only categories with entries are shown.
  static const categories = <String>[
    'Chat & replies',
    'Characters & the Party',
    'Voice',
    'Images',
    'Stage & Pocket',
    'Installing & updates',
    'Something else',
  ];

  /// The out-of-beta test, as written into the file when the batch is
  /// marked out of beta. The screen shows the same three points in
  /// fuller words (see the FAQ copy).
  static const outOfBetaTestItems = <String>[
    'Everything Alice ships with works',
    'No placeholders left',
    'Ready to charge for (\$25 one-time, from v2.0)',
  ];

  DateTime fileOpened;
  FeedbackJumpMark jumpMark;
  final List<FeedbackEntry> entries;

  static String _field(String value) =>
      value.trim().isEmpty ? 'not given' : value.trim();

  static const _months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String formatDate(DateTime date) =>
      '${_months[date.month - 1]} ${date.day}, ${date.year}';

  static DateTime? _parseDate(String text) {
    final match = RegExp(
      r'^(\w+) (\d+), (\d+)$',
    ).firstMatch(text.trim());
    if (match == null) return null;
    final month = _months.indexOf(match.group(1)!);
    if (month < 0) return null;
    final day = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || year == null) return null;
    return DateTime(year, month + 1, day);
  }

  /// The markdown the user downloads — the same text the screen shows.
  String renderMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Alice — Feedback File');
    buffer.writeln();
    buffer.writeln(jumpMark.fileLine);
    if (jumpMark == FeedbackJumpMark.outOfBeta) {
      buffer.writeln('Out-of-beta test:');
      for (final item in outOfBetaTestItems) {
        buffer.writeln('- $item');
      }
    }
    buffer.writeln('File opened: ${formatDate(fileOpened)}');
    buffer.writeln('Entries: ${entries.length}');
    var number = 0;
    for (final category in categories) {
      final inCategory =
          entries.where((entry) => entry.category == category).toList();
      if (inCategory.isEmpty) continue;
      buffer.writeln();
      buffer.writeln('## $category');
      for (final entry in inCategory) {
        number++;
        buffer.writeln();
        buffer.writeln(
          '### $number. [${entry.kind.label}] ${_field(entry.what)}',
        );
        buffer.writeln();
        buffer.writeln('- Who: ${_field(entry.who)}');
        buffer.writeln('- What: ${_field(entry.what)}');
        buffer.writeln('- When: ${_field(entry.when)}');
        buffer.writeln('- Where: ${_field(entry.where)}');
        buffer.writeln('- Why: ${_field(entry.why)}');
        buffer.writeln('- How: ${_field(entry.how)}');
      }
    }
    return buffer.toString();
  }

  /// Parses markdown this class wrote. Lenient on purpose: a missing
  /// jump mark reads as a version change, a missing or unreadable date
  /// reads as today, and an unknown category lands in 'Something
  /// else' — a hand-edited file still loads instead of failing.
  static FeedbackFile parse(String text) {
    var mark = FeedbackJumpMark.versionChange;
    var opened = DateTime.now();
    final entries = <FeedbackEntry>[];
    var category = 'Something else';
    var inEntry = false;
    FeedbackKind kind = FeedbackKind.request;
    var who = '';
    var what = '';
    var when = '';
    var where = '';
    var why = '';
    var how = '';

    void flush() {
      if (!inEntry) return;
      entries.add(
        FeedbackEntry(
          kind: kind,
          category: category,
          who: who,
          what: what,
          when: when,
          where: where,
          why: why,
          how: how,
        ),
      );
      inEntry = false;
      kind = FeedbackKind.request;
      who = '';
      what = '';
      when = '';
      where = '';
      why = '';
      how = '';
    }

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.startsWith('Jump mark:')) {
        if (line.contains('OUT OF BETA')) {
          mark = FeedbackJumpMark.outOfBeta;
        }
        continue;
      }
      if (line.startsWith('File opened:')) {
        opened =
            _parseDate(line.substring('File opened:'.length)) ?? DateTime.now();
        continue;
      }
      if (line.startsWith('## ')) {
        flush();
        final name = line.substring(3).trim();
        category = categories.contains(name) ? name : 'Something else';
        continue;
      }
      final heading = RegExp(
        r'^### \d+\. \[(Request|Complaint)\] (.*)$',
      ).firstMatch(line);
      if (heading != null) {
        flush();
        inEntry = true;
        kind = heading.group(1) == 'Complaint'
            ? FeedbackKind.complaint
            : FeedbackKind.request;
        what = heading.group(2)!.trim();
        continue;
      }
      final field = RegExp(
        r'^- (Who|What|When|Where|Why|How): ?(.*)$',
      ).firstMatch(line);
      if (field != null && inEntry) {
        final value = field.group(2)!.trim();
        final unmarked = value == 'not given' ? '' : value;
        switch (field.group(1)) {
          case 'Who':
            who = unmarked;
          case 'What':
            what = unmarked;
          case 'When':
            when = unmarked;
          case 'Where':
            where = unmarked;
          case 'Why':
            why = unmarked;
          case 'How':
            how = unmarked;
        }
        continue;
      }
    }
    flush();
    return FeedbackFile(
      fileOpened: opened,
      jumpMark: mark,
      entries: entries,
    );
  }
}

/// Reads and writes the running file under a directory — the caller
/// passes the user-visible feedback folder, never a hidden path.
class FeedbackFileService {
  FeedbackFileService(this.directory);

  final Directory directory;

  File get file => File(path.join(directory.path, FeedbackFile.fileName));

  /// Loads the file, or an empty one (opened today) when there is
  /// nothing on disk yet. A file that exists but will not parse still
  /// loads as empty rather than failing the screen — the entries are
  /// only ever lost if the file itself is gone.
  Future<FeedbackFile> load() async {
    if (!await file.exists()) {
      return FeedbackFile(fileOpened: DateTime.now());
    }
    return FeedbackFile.parse(await file.readAsString());
  }

  Future<void> save(FeedbackFile data) async {
    await directory.create(recursive: true);
    await file.writeAsString(data.renderMarkdown());
  }

  /// Starts a fresh file: the on-disk file is deleted, and the next
  /// entry opens a new one.
  Future<void> clear() async {
    if (await file.exists()) await file.delete();
  }
}
