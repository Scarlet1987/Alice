// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice FAQ, the web port of lib/ui/alice/v9/alice_v9_faq.dart — from
// the approved preview (Space alice-faq-feedback-preview, Elaina
// 2026-11-14: "that is perfect lets do this as the faq feature"):
// the policy questions, the draft guide in its two audience groups,
// and the suggestion box feeding the one running file.
//
// The web has no local data-root file like the desktop's
// <data root>/feedback/alice-feedback-file.md, so the running file's
// markdown lives in localStorage as the same text (the file is the
// record), and Download / Copy produce that file for upload. Nothing
// is sent anywhere from this screen.

import { useState } from 'react';
import { Link } from 'react-router-dom';
import {
  FEEDBACK_CATEGORIES,
  FEEDBACK_FILE_NAME,
  JUMP_MARK_LABELS,
  clearFeedbackFile,
  createEmptyFeedbackFile,
  formatFeedbackDate,
  loadFeedbackFile,
  renderFeedbackMarkdown,
  saveFeedbackFile,
  type FeedbackEntry,
  type FeedbackFileData,
  type FeedbackJumpMark,
  type FeedbackKind,
} from '../lib/feedbackFile';
import {
  FAQ_BASICS,
  FAQ_DONE_LIST,
  FAQ_FIELDS,
  FAQ_POLICY,
  FAQ_SILLY_TAVERN,
  type FaqQA,
} from '../lib/faqContent';

function fieldText(value: string): string {
  const trimmed = value.trim();
  return trimmed === '' ? 'not given' : trimmed;
}

/** One pre-answered question: the question always shows, the answer opens on tap. The first item of a group starts open. */
function FaqItem({ qa, open: startOpen }: { qa: FaqQA; open?: boolean }) {
  const [open, setOpen] = useState(startOpen ?? false);
  return (
    <div className="faq-qa">
      <button
        type="button"
        className="faq-qa-q"
        aria-expanded={open}
        onClick={() => setOpen(!open)}
      >
        <span>{qa.question}</span>
        <span className="faq-qa-toggle" aria-hidden>
          {open ? '−' : '+'}
        </span>
      </button>
      {open && <p className="faq-qa-a">{qa.answer}</p>}
    </div>
  );
}

export function FaqPage() {
  const [file, setFile] = useState<FeedbackFileData>(() =>
    loadFeedbackFile(window.localStorage),
  );
  const [kind, setKind] = useState<FeedbackKind>('request');
  const [category, setCategory] = useState<string>(FEEDBACK_CATEGORIES[0]);
  const [values, setValues] = useState<Record<string, string>>({});
  const [formError, setFormError] = useState<string | null>(null);
  const [formNote, setFormNote] = useState<string | null>(null);
  const [fileNote, setFileNote] = useState<string | null>(null);

  const persist = (next: FeedbackFileData) => {
    saveFeedbackFile(window.localStorage, next);
    setFile(next);
  };

  const valueOf = (id: string) => values[id] ?? '';
  const setValue = (id: string, value: string) =>
    setValues((prev) => ({ ...prev, [id]: value }));

  const submit = () => {
    const what = valueOf('what').trim();
    if (what === '') {
      setFormError(
        'The file needs the What — everything else can be filled in as best you can.',
      );
      setFormNote(null);
      return;
    }
    const entry: FeedbackEntry = {
      kind,
      category,
      who: valueOf('who'),
      what,
      when: valueOf('when'),
      where: valueOf('where'),
      why: valueOf('why'),
      how: valueOf('how'),
    };
    persist({ ...file, entries: [...file.entries, entry] });
    setValues({});
    setFormError(null);
    setFormNote("Added — it's in the file, under its category.");
  };

  const setMark = (mark: FeedbackJumpMark) => {
    persist({ ...file, jumpMark: mark });
  };

  const removeEntry = (index: number) => {
    persist({
      ...file,
      entries: file.entries.filter((_, i) => i !== index),
    });
  };

  const freshFile = () => {
    if (
      !window.confirm(
        'This clears every entry in the running file and starts a new one. Download or copy the file first if you want to keep it.',
      )
    ) {
      return;
    }
    clearFeedbackFile(window.localStorage);
    setFile(createEmptyFeedbackFile());
    setFileNote(null);
  };

  const copy = async () => {
    try {
      if (!navigator.clipboard) throw new Error('no clipboard');
      await navigator.clipboard.writeText(renderFeedbackMarkdown(file));
      setFileNote('Copied — ready to paste or send.');
    } catch {
      setFileNote('Copy is not available here — use Download the file instead.');
    }
  };

  const download = () => {
    const blob = new Blob([renderFeedbackMarkdown(file)], {
      type: 'text/markdown',
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = FEEDBACK_FILE_NAME;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  };

  // Entries grouped by category in file order, numbered across the
  // whole file the way the markdown numbers them.
  const groups: { category: string; items: { entry: FeedbackEntry; index: number; number: number }[] }[] = [];
  let number = 0;
  for (const groupCategory of FEEDBACK_CATEGORIES) {
    const items: { entry: FeedbackEntry; index: number; number: number }[] = [];
    file.entries.forEach((entry, index) => {
      if (entry.category !== groupCategory) return;
      number += 1;
      items.push({ entry, index, number });
    });
    if (items.length > 0) groups.push({ category: groupCategory, items });
  }

  return (
    <div className="page faq-page">
      <Link className="faq-back" to="/">
        ← Back
      </Link>
      <h1 className="faq-title">
        Questions, complaints &amp; <em>requests</em>
      </h1>
      <p className="faq-lede">
        Everything sent through the suggestion box below lands in one running file,
        sorted as it arrives. When the file is uploaded, the changes get worked
        through together — and Alice moves in large jumps shaped by the categories
        the feedback came in under.
      </p>
      <p>
        <span className="faq-beta-pill">Alice is free while it&rsquo;s in beta.</span>
      </p>

      <section className="faq-card" aria-label="Frequently asked questions">
        <h2 className="faq-heading">Frequently asked questions</h2>
        {FAQ_POLICY.map((qa, i) => (
          <FaqItem key={qa.question} qa={qa} open={i === 0} />
        ))}
      </section>

      <section className="faq-card" aria-label="New here? Start with these">
        <div className="faq-card-head">
          <h2 className="faq-heading">New here? Start with these</h2>
          <span className="faq-draft-tag">Draft — for approval</span>
        </div>
        <p className="faq-muted">
          Two kinds of people land here. Folks coming from a much simpler app need
          the basics, answered plainly. Folks coming from SillyTavern go looking
          for the detailed things that program has — character cards, presets,
          lorebooks — and want to know where each one lives in Alice. Both sets
          are below, anticipated from what Alice does — nobody has sent them
          through the suggestion box yet, and the wording is Elaina&rsquo;s to
          approve or change.
        </p>
        <h3 className="faq-group-title">Start with the basics</h3>
        <p className="faq-group-sub">
          New to this kind of app? These are the questions an FAQ can answer outright.
        </p>
        {FAQ_BASICS.map((qa, i) => (
          <FaqItem key={qa.question} qa={qa} open={i === 0} />
        ))}
        <h3 className="faq-group-title">Coming from SillyTavern</h3>
        <p className="faq-group-sub">
          The common things that program has, and where each one lives in Alice.
        </p>
        {FAQ_SILLY_TAVERN.map((qa) => (
          <FaqItem key={qa.question} qa={qa} />
        ))}
      </section>

      <div className="faq-split">
        <section className="faq-card" aria-label="The suggestion box">
          <h2 className="faq-heading">The suggestion box</h2>
          <p className="faq-muted">
            Six questions, the same six every time — so nothing arrives half-told.
          </p>
          <p className="faq-field-label">This is a</p>
          <div className="faq-kind-row" role="group" aria-label="Kind">
            {(['request', 'complaint'] as const).map((k) => (
              <button
                key={k}
                type="button"
                className={kind === k ? 'faq-btn faq-btn-small' : 'faq-btn faq-btn-small faq-btn-ghost'}
                aria-pressed={kind === k}
                onClick={() => setKind(k)}
              >
                {k === 'request' ? 'Request' : 'Complaint'}
              </button>
            ))}
          </div>
          <label className="faq-field" htmlFor="faq-category">
            <span className="faq-field-label">Category</span>
            <select
              id="faq-category"
              value={category}
              onChange={(e) => setCategory(e.target.value)}
            >
              {FEEDBACK_CATEGORIES.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          </label>
          <p className="faq-muted">the file groups by this</p>
          {FAQ_FIELDS.map((field) => (
            <label className="faq-field" key={field.id} htmlFor={`faq-field-${field.id}`}>
              <span className="faq-field-label">{field.label}</span>
              <span className="faq-field-question">{field.question}</span>
              <span className="faq-field-hint">{field.hint}</span>
              {field.id === 'what' || field.id === 'how' ? (
                <textarea
                  id={`faq-field-${field.id}`}
                  rows={3}
                  placeholder={field.placeholder}
                  value={valueOf(field.id)}
                  onChange={(e) => setValue(field.id, e.target.value)}
                />
              ) : (
                <input
                  id={`faq-field-${field.id}`}
                  type="text"
                  placeholder={field.placeholder}
                  value={valueOf(field.id)}
                  onChange={(e) => setValue(field.id, e.target.value)}
                />
              )}
            </label>
          ))}
          {formError !== null && <p className="faq-note">{formError}</p>}
          <button type="button" className="faq-btn" onClick={submit}>
            Add it to the file
          </button>
          {formNote !== null && <p className="faq-note">{formNote}</p>}
        </section>

        <section className="faq-card" aria-label="The running file">
          <h2 className="faq-heading">The running file</h2>
          <p className="faq-muted">
            One file, collecting until it&rsquo;s uploaded and worked through. This is
            exactly what the uploaded file looks like.
          </p>
          <p className="faq-file-meta">
            File opened {formatFeedbackDate(file.fileOpened)} · {file.entries.length}{' '}
            {file.entries.length === 1 ? 'entry' : 'entries'} · grouped by category,
            six fields each
          </p>
          <p className="faq-field-label">
            Jump mark for this batch — written into the file, so it&rsquo;s certain
          </p>
          {(['versionChange', 'outOfBeta'] as const).map((mark) => (
            <button
              key={mark}
              type="button"
              className={
                file.jumpMark === mark
                  ? 'faq-btn faq-btn-small faq-btn-block'
                  : 'faq-btn faq-btn-small faq-btn-block faq-btn-ghost'
              }
              aria-pressed={file.jumpMark === mark}
              onClick={() => setMark(mark)}
            >
              {JUMP_MARK_LABELS[mark]}
            </button>
          ))}
          {file.jumpMark === 'outOfBeta' && (
            <div className="faq-done-list">
              <h3 className="faq-done-title">The out-of-beta test</h3>
              {FAQ_DONE_LIST.map((item) => (
                <p key={item} className="faq-done-item">
                  •&nbsp;&nbsp;{item}
                </p>
              ))}
            </div>
          )}
          {file.entries.length === 0 ? (
            <p className="faq-muted">
              Nothing collected yet. The first entry added in the suggestion box
              starts the file.
            </p>
          ) : (
            groups.map((group) => (
              <div key={group.category}>
                <h3 className="faq-entry-group">
                  {group.category} — {group.items.length}{' '}
                  {group.items.length === 1 ? 'entry' : 'entries'}
                </h3>
                {group.items.map(({ entry, index, number: n }) => (
                  <div key={`${index}-${n}`} className="faq-entry">
                    <p className="faq-entry-title">
                      {n}. [{entry.kind === 'complaint' ? 'Complaint' : 'Request'}]{' '}
                      {fieldText(entry.what)}
                    </p>
                    {[
                      `Who: ${fieldText(entry.who)}`,
                      `What: ${fieldText(entry.what)}`,
                      `When: ${fieldText(entry.when)}`,
                      `Where: ${fieldText(entry.where)}`,
                      `Why: ${fieldText(entry.why)}`,
                      `How: ${fieldText(entry.how)}`,
                    ].map((line) => (
                      <p key={line} className="faq-entry-line">
                        {line}
                      </p>
                    ))}
                    <button
                      type="button"
                      className="faq-btn faq-btn-small faq-btn-ghost"
                      onClick={() => removeEntry(index)}
                    >
                      Remove this entry
                    </button>
                  </div>
                ))}
              </div>
            ))
          )}
          <div className="faq-actions">
            <button type="button" className="faq-btn faq-btn-small" onClick={download}>
              Download the file
            </button>
            <button type="button" className="faq-btn faq-btn-small faq-btn-ghost" onClick={copy}>
              Copy the file
            </button>
            <button
              type="button"
              className="faq-btn faq-btn-small faq-btn-ghost"
              onClick={freshFile}
            >
              Start a fresh file
            </button>
          </div>
          {fileNote !== null && <p className="faq-note">{fileNote}</p>}
          <p className="faq-muted">
            Feedback sent here is collected into the running file only — download it
            and upload it when you&rsquo;re ready to work through the changes.
          </p>
        </section>
      </div>
    </div>
  );
}
