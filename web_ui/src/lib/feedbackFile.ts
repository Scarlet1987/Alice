// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// The running feedback file: one markdown record that keeps collecting
// every complaint and request from the FAQ suggestion box, heavily
// organized — entries grouped by category, each one carrying who, what,
// when, where, why, and how. The web port of
// lib/services/feedback_file_service.dart. The markdown this renders is
// byte-identical to the Dart side's, so a file downloaded on the web
// and one downloaded on desktop are the same file.
//
// The web has no local data-root file like the desktop's
// <data root>/feedback/alice-feedback-file.md, so the record lives in
// localStorage as the same markdown text (the file is the record, not
// a second copy of it), and Download / Copy produce that file for
// upload. Nothing is sent anywhere from here.

export type FeedbackKind = 'request' | 'complaint';

export type FeedbackJumpMark = 'versionChange' | 'outOfBeta';

export const FEEDBACK_FILE_NAME = 'alice-feedback-file.md';

/** localStorage key holding the running file's markdown text. */
export const FEEDBACK_STORAGE_KEY = 'alice-feedback-file';

/** Categories in file order. Only categories with entries are shown. */
export const FEEDBACK_CATEGORIES = [
  'Chat & replies',
  'Characters & the Party',
  'Voice',
  'Images',
  'Stage & Pocket',
  'Installing & updates',
  'Something else',
] as const;

export const JUMP_MARK_LABELS: Record<FeedbackJumpMark, string> = {
  versionChange: 'Version change — still beta, still free',
  outOfBeta: 'Out of beta — the v2.0 jump',
};

const JUMP_MARK_FILE_LINES: Record<FeedbackJumpMark, string> = {
  versionChange: 'Jump mark: VERSION CHANGE — still in beta, still free',
  outOfBeta: 'Jump mark: OUT OF BETA — the v2.0 jump',
};

/** The out-of-beta test, as written into the file when the batch is marked out of beta. */
export const OUT_OF_BETA_TEST_ITEMS = [
  'Everything Alice ships with works',
  'No placeholders left',
  'Ready to charge for ($25 one-time, from v2.0)',
] as const;

export interface FeedbackEntry {
  kind: FeedbackKind;
  category: string;
  who: string;
  what: string;
  when: string;
  where: string;
  why: string;
  how: string;
}

export interface FeedbackFileData {
  fileOpened: Date;
  jumpMark: FeedbackJumpMark;
  entries: FeedbackEntry[];
}

export function createEmptyFeedbackFile(opened: Date = new Date()): FeedbackFileData {
  return { fileOpened: opened, jumpMark: 'versionChange', entries: [] };
}

function field(value: string): string {
  const trimmed = value.trim();
  return trimmed === '' ? 'not given' : trimmed;
}

const MONTHS = [
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

export function formatFeedbackDate(date: Date): string {
  return `${MONTHS[date.getMonth()]} ${date.getDate()}, ${date.getFullYear()}`;
}

function parseFeedbackDate(text: string): Date | null {
  const match = /^(\w+) (\d+), (\d+)$/.exec(text.trim());
  if (match === null) return null;
  const month = MONTHS.indexOf(match[1]);
  if (month < 0) return null;
  const day = Number(match[2]);
  const year = Number(match[3]);
  if (!Number.isInteger(day) || !Number.isInteger(year)) return null;
  return new Date(year, month, day);
}

/** The markdown the user downloads — the same text the screen shows. */
export function renderFeedbackMarkdown(file: FeedbackFileData): string {
  const lines: string[] = ['# Alice — Feedback File', '', JUMP_MARK_FILE_LINES[file.jumpMark]];
  if (file.jumpMark === 'outOfBeta') {
    lines.push('Out-of-beta test:');
    for (const item of OUT_OF_BETA_TEST_ITEMS) lines.push(`- ${item}`);
  }
  lines.push(`File opened: ${formatFeedbackDate(file.fileOpened)}`);
  lines.push(`Entries: ${file.entries.length}`);
  let number = 0;
  for (const category of FEEDBACK_CATEGORIES) {
    const inCategory = file.entries.filter((entry) => entry.category === category);
    if (inCategory.length === 0) continue;
    lines.push('', `## ${category}`);
    for (const entry of inCategory) {
      number += 1;
      const kindLabel = entry.kind === 'complaint' ? 'Complaint' : 'Request';
      lines.push(
        '',
        `### ${number}. [${kindLabel}] ${field(entry.what)}`,
        '',
        `- Who: ${field(entry.who)}`,
        `- What: ${field(entry.what)}`,
        `- When: ${field(entry.when)}`,
        `- Where: ${field(entry.where)}`,
        `- Why: ${field(entry.why)}`,
        `- How: ${field(entry.how)}`,
      );
    }
  }
  return `${lines.join('\n')}\n`;
}

/**
 * Parses markdown this module wrote. Lenient on purpose: a missing
 * jump mark reads as a version change, a missing or unreadable date
 * reads as today, and an unknown category lands in 'Something
 * else' — a hand-edited file still loads instead of failing.
 */
export function parseFeedbackMarkdown(text: string): FeedbackFileData {
  let mark: FeedbackJumpMark = 'versionChange';
  let opened = new Date();
  const entries: FeedbackEntry[] = [];
  let category = 'Something else';
  let inEntry = false;
  let kind: FeedbackKind = 'request';
  let who = '';
  let what = '';
  let when = '';
  let where = '';
  let why = '';
  let how = '';

  const flush = () => {
    if (!inEntry) return;
    entries.push({ kind, category, who, what, when, where, why, how });
    inEntry = false;
    kind = 'request';
    who = '';
    what = '';
    when = '';
    where = '';
    why = '';
    how = '';
  };

  for (const rawLine of text.split('\n')) {
    const line = rawLine.trim();
    if (line.startsWith('Jump mark:')) {
      if (line.includes('OUT OF BETA')) mark = 'outOfBeta';
      continue;
    }
    if (line.startsWith('File opened:')) {
      opened = parseFeedbackDate(line.slice('File opened:'.length)) ?? new Date();
      continue;
    }
    if (line.startsWith('## ')) {
      flush();
      const name = line.slice(3).trim();
      category = (FEEDBACK_CATEGORIES as readonly string[]).includes(name)
        ? name
        : 'Something else';
      continue;
    }
    const heading = /^### \d+\. \[(Request|Complaint)\] (.*)$/.exec(line);
    if (heading !== null) {
      flush();
      inEntry = true;
      kind = heading[1] === 'Complaint' ? 'complaint' : 'request';
      what = heading[2].trim();
      continue;
    }
    const fieldMatch = /^- (Who|What|When|Where|Why|How): ?(.*)$/.exec(line);
    if (fieldMatch !== null && inEntry) {
      const value = fieldMatch[2].trim();
      const unmarked = value === 'not given' ? '' : value;
      switch (fieldMatch[1]) {
        case 'Who':
          who = unmarked;
          break;
        case 'What':
          what = unmarked;
          break;
        case 'When':
          when = unmarked;
          break;
        case 'Where':
          where = unmarked;
          break;
        case 'Why':
          why = unmarked;
          break;
        case 'How':
          how = unmarked;
          break;
      }
      continue;
    }
  }
  flush();
  return { fileOpened: opened, jumpMark: mark, entries };
}

/** Loads the running file from storage, or an empty one (opened today) when there is nothing saved yet. */
export function loadFeedbackFile(storage: Storage): FeedbackFileData {
  const raw = storage.getItem(FEEDBACK_STORAGE_KEY);
  if (raw === null) return createEmptyFeedbackFile();
  try {
    return parseFeedbackMarkdown(raw);
  } catch {
    return createEmptyFeedbackFile();
  }
}

export function saveFeedbackFile(storage: Storage, file: FeedbackFileData): void {
  storage.setItem(FEEDBACK_STORAGE_KEY, renderFeedbackMarkdown(file));
}

/** Starts a fresh file: the stored record is deleted, and the next entry opens a new one. */
export function clearFeedbackFile(storage: Storage): void {
  storage.removeItem(FEEDBACK_STORAGE_KEY);
}
