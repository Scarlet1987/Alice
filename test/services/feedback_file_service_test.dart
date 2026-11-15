// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// The running feedback file: rendering, grouping, the jump mark, and
// the parse round-trip. Pure Dart — no widgets, no Flutter binding.
// UNRUN in the VM that wrote it (no Flutter/Dart there) — run on metal:
//   flutter test test/services/feedback_file_service_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_porch_ai/services/feedback_file_service.dart';

FeedbackEntry _entry({
  FeedbackKind kind = FeedbackKind.request,
  String category = 'Chat & replies',
  String who = 'Sam R.',
  String what = 'Replies stop mid-sentence on long chats',
  String when = 'Evenings',
  String where = 'On the Stage',
  String why = 'It breaks the scene',
  String how = 'Talk for twenty minutes',
}) {
  return FeedbackEntry(
    kind: kind,
    category: category,
    who: who,
    what: what,
    when: when,
    where: where,
    why: why,
    how: how,
  );
}

void main() {
  group('FeedbackFile render', () {
    test('an empty file renders its header and no categories', () {
      final file = FeedbackFile(fileOpened: DateTime(2026, 11, 15));
      final text = file.renderMarkdown();
      expect(text, contains('# Alice — Feedback File'));
      expect(
        text,
        contains('Jump mark: VERSION CHANGE — still in beta, still free'),
      );
      expect(text, contains('File opened: November 15, 2026'));
      expect(text, contains('Entries: 0'));
      expect(text, isNot(contains('## ')));
    });

    test('entries group by category in file order, numbered across it', () {
      final file = FeedbackFile(fileOpened: DateTime(2026, 11, 15));
      file.entries.addAll([
        _entry(category: 'Voice', what: 'A slower speaking speed'),
        _entry(category: 'Chat & replies', what: 'Replies stop mid-sentence'),
        _entry(
          category: 'Chat & replies',
          what: 'A second chat request',
          who: '',
        ),
      ]);
      final text = file.renderMarkdown();
      // Chat comes before Voice in file order, even though the Voice
      // entry arrived first. The markdown groups by plain category
      // headings; the "— N entries" count is the screen's, not the
      // file's.
      expect(text, contains('## Chat & replies'));
      expect(text, contains('## Voice'));
      expect(
        text.indexOf('## Chat & replies'),
        lessThan(text.indexOf('## Voice')),
      );
      expect(text, contains('### 1. [Request] Replies stop mid-sentence'));
      expect(text, contains('### 2. [Request] A second chat request'));
      expect(text, contains('### 3. [Request] A slower speaking speed'));
      expect(text, contains('- Who: not given'));
    });

    test('out-of-beta render carries the mark and the test block', () {
      final file = FeedbackFile(
        fileOpened: DateTime(2026, 11, 15),
        jumpMark: FeedbackJumpMark.outOfBeta,
      );
      final text = file.renderMarkdown();
      expect(text, contains('Jump mark: OUT OF BETA — the v2.0 jump'));
      expect(text, contains('Out-of-beta test:'));
      expect(text, contains('- Everything Alice ships with works'));
      expect(text, contains('- No placeholders left'));
      expect(
        text,
        contains('- Ready to charge for (\$25 one-time, from v2.0)'),
      );
    });

    test('parse(render(x)) is byte-identical', () {
      final file = FeedbackFile(
        fileOpened: DateTime(2026, 11, 15),
        jumpMark: FeedbackJumpMark.outOfBeta,
      );
      file.entries.addAll([
        _entry(kind: FeedbackKind.complaint),
        _entry(category: 'Voice', what: 'A slower speaking speed', who: ''),
        _entry(category: 'Chat & replies', what: 'A second chat request'),
      ]);
      final first = file.renderMarkdown();
      final parsed = FeedbackFile.parse(first);
      expect(parsed.renderMarkdown(), first);
      expect(parsed.jumpMark, FeedbackJumpMark.outOfBeta);
      expect(parsed.fileOpened, DateTime(2026, 11, 15));
      expect(parsed.entries.length, 3);
      expect(parsed.entries[0].kind, FeedbackKind.complaint);
      // Parsed entries come back in file (grouped) order, not
      // insertion order: the Voice entry is last in the file.
      final voice = parsed.entries.firstWhere(
        (entry) => entry.category == 'Voice',
      );
      expect(voice.who, '');
      expect(voice.what, 'A slower speaking speed');
    });

    test('parse is lenient with a hand-edited file', () {
      const text = '''
# Alice — Feedback File

Jump mark: VERSION CHANGE — still in beta, still free
Entries: 1

## Odd place

### 1. [Request] Something I noticed

- Who: Sam R.
- What: Something I noticed
''';
      final parsed = FeedbackFile.parse(text);
      expect(parsed.jumpMark, FeedbackJumpMark.versionChange);
      expect(parsed.entries.length, 1);
      // An unknown category lands in 'Something else'.
      expect(parsed.entries.first.category, 'Something else');
      // A missing date reads as today, not a crash.
      expect(parsed.fileOpened.year, DateTime.now().year);
      expect(parsed.entries.first.when, '');
    });
  });

  group('FeedbackFileService', () {
    late Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('feedback_file_test_');
    });

    tearDown(() {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });

    test('load, save, and clear round-trip on disk', () async {
      final service = FeedbackFileService(temp);
      final empty = await service.load();
      expect(empty.entries, isEmpty);
      expect(await service.file.exists(), isFalse);

      empty.entries.add(_entry());
      await service.save(empty);
      expect(await service.file.exists(), isTrue);
      expect(service.file.path.endsWith('alice-feedback-file.md'), isTrue);

      final loaded = await service.load();
      expect(loaded.entries.length, 1);
      expect(
        loaded.entries.first.what,
        'Replies stop mid-sentence on long chats',
      );
      expect(loaded.entries.first.who, 'Sam R.');

      await service.clear();
      expect(await service.file.exists(), isFalse);
      expect((await service.load()).entries, isEmpty);
    });
  });
}
