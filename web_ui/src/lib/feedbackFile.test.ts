// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// The running feedback file: rendering, grouping, the jump mark, and
// the parse round-trip — the web port of the Dart service tests
// (test/services/feedback_file_service_test.dart). Pure logic, no
// network, no running app. The markdown this renders must be
// byte-identical to the Dart side's, so a file downloaded on the web
// and one downloaded on desktop are the same file.

import { describe, expect, it, beforeEach, afterEach } from 'vitest';
import {
  FEEDBACK_STORAGE_KEY,
  clearFeedbackFile,
  createEmptyFeedbackFile,
  loadFeedbackFile,
  parseFeedbackMarkdown,
  renderFeedbackMarkdown,
  saveFeedbackFile,
  type FeedbackEntry,
} from './feedbackFile';

function entry(overrides: Partial<FeedbackEntry> = {}): FeedbackEntry {
  return {
    kind: 'request',
    category: 'Chat & replies',
    who: 'Sam R.',
    what: 'Replies stop mid-sentence on long chats',
    when: 'Evenings',
    where: 'On the Stage',
    why: 'It breaks the scene',
    how: 'Talk for twenty minutes',
    ...overrides,
  };
}

const OPENED = new Date(2026, 10, 15);

describe('renderFeedbackMarkdown', () => {
  it('an empty file renders its header and no categories', () => {
    const text = renderFeedbackMarkdown(createEmptyFeedbackFile(OPENED));
    expect(text).toContain('# Alice — Feedback File');
    expect(text).toContain('Jump mark: VERSION CHANGE — still in beta, still free');
    expect(text).toContain('File opened: November 15, 2026');
    expect(text).toContain('Entries: 0');
    expect(text).not.toContain('## ');
  });

  it('entries group by category in file order, numbered across it', () => {
    const file = createEmptyFeedbackFile(OPENED);
    file.entries.push(
      entry({ category: 'Voice', what: 'A slower speaking speed' }),
      entry({ category: 'Chat & replies', what: 'Replies stop mid-sentence' }),
      entry({ category: 'Chat & replies', what: 'A second chat request', who: '' }),
    );
    const text = renderFeedbackMarkdown(file);
    // Chat comes before Voice in file order, even though the Voice
    // entry arrived first.
    expect(text).toContain('## Chat & replies');
    expect(text).toContain('## Voice');
    expect(text.indexOf('## Chat & replies')).toBeLessThan(text.indexOf('## Voice'));
    expect(text).toContain('### 1. [Request] Replies stop mid-sentence');
    expect(text).toContain('### 2. [Request] A second chat request');
    expect(text).toContain('### 3. [Request] A slower speaking speed');
    expect(text).toContain('- Who: not given');
  });

  it('out-of-beta render carries the mark and the test block', () => {
    const file = createEmptyFeedbackFile(OPENED);
    file.jumpMark = 'outOfBeta';
    const text = renderFeedbackMarkdown(file);
    expect(text).toContain('Jump mark: OUT OF BETA — the v2.0 jump');
    expect(text).toContain('Out-of-beta test:');
    expect(text).toContain('- Everything Alice ships with works');
    expect(text).toContain('- No placeholders left');
    expect(text).toContain('- Ready to charge for ($25 one-time, from v2.0)');
  });

  it('parse(render(x)) is byte-identical', () => {
    const file = createEmptyFeedbackFile(OPENED);
    file.jumpMark = 'outOfBeta';
    file.entries.push(
      entry({ kind: 'complaint' }),
      entry({ category: 'Voice', what: 'A slower speaking speed', who: '' }),
      entry({ category: 'Chat & replies', what: 'A second chat request' }),
    );
    const first = renderFeedbackMarkdown(file);
    const parsed = parseFeedbackMarkdown(first);
    expect(renderFeedbackMarkdown(parsed)).toBe(first);
    expect(parsed.jumpMark).toBe('outOfBeta');
    expect(parsed.fileOpened.getTime()).toBe(OPENED.getTime());
    expect(parsed.entries.length).toBe(3);
    expect(parsed.entries[0].kind).toBe('complaint');
    // Parsed entries come back in file (grouped) order, not
    // insertion order: the Voice entry is last in the file.
    const voice = parsed.entries.find((e) => e.category === 'Voice');
    expect(voice?.who).toBe('');
    expect(voice?.what).toBe('A slower speaking speed');
  });

  it('parse is lenient with a hand-edited file', () => {
    const text = `# Alice — Feedback File

Jump mark: VERSION CHANGE — still in beta, still free
Entries: 1

## Odd place

### 1. [Request] Something I noticed

- Who: Sam R.
- What: Something I noticed
`;
    const parsed = parseFeedbackMarkdown(text);
    expect(parsed.jumpMark).toBe('versionChange');
    expect(parsed.entries.length).toBe(1);
    // An unknown category lands in 'Something else'.
    expect(parsed.entries[0].category).toBe('Something else');
    // A missing date reads as today, not a crash.
    expect(parsed.fileOpened.getFullYear()).toBe(new Date().getFullYear());
    expect(parsed.entries[0].when).toBe('');
  });
});

describe('feedback file storage', () => {
  beforeEach(() => {
    window.localStorage.removeItem(FEEDBACK_STORAGE_KEY);
  });

  afterEach(() => {
    window.localStorage.removeItem(FEEDBACK_STORAGE_KEY);
  });

  it('load, save, and clear round-trip in localStorage', () => {
    const storage = window.localStorage;
    const empty = loadFeedbackFile(storage);
    expect(empty.entries).toEqual([]);
    expect(storage.getItem(FEEDBACK_STORAGE_KEY)).toBeNull();

    empty.entries.push(entry());
    saveFeedbackFile(storage, empty);
    expect(storage.getItem(FEEDBACK_STORAGE_KEY)).toContain(
      '# Alice — Feedback File',
    );

    const loaded = loadFeedbackFile(storage);
    expect(loaded.entries.length).toBe(1);
    expect(loaded.entries[0].what).toBe('Replies stop mid-sentence on long chats');
    expect(loaded.entries[0].who).toBe('Sam R.');

    clearFeedbackFile(storage);
    expect(storage.getItem(FEEDBACK_STORAGE_KEY)).toBeNull();
    expect(loadFeedbackFile(storage).entries).toEqual([]);
  });
});
