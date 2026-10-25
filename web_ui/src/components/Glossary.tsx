// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Web mirror of the desktop plain-English glossary (MC, NPC, User, Persona,
// Lorebook, Greeting). A dialog listing every term plus inline term chips.

import { useState } from 'react';

export interface GlossaryEntry {
  term: string;
  short: string;
  definition: string;
}

export const GLOSSARY: GlossaryEntry[] = [
  {
    term: 'MC',
    short: 'Main Character',
    definition:
      'The primary character you chat with. A character card describes the MC: their personality, appearance, voice and story. That is them — not you.',
  },
  {
    term: 'NPC',
    short: 'Non-Playable Character',
    definition:
      'Supporting cast members in group chats. NPCs talk and act on their own, but the story revolves around you and the MC.',
  },
  {
    term: 'User',
    short: 'You, the account holder',
    definition:
      'The human holding the device. Your persona tells the AI who it is talking to. Your details are kept separate and are never mixed into a character\u2019s data.',
  },
  {
    term: 'Persona',
    short: 'Your stand-in',
    definition:
      'The name, description and picture the AI sees for you in chat. Edit it any time — the MC still meets whoever you decide to be.',
  },
  {
    term: 'Lorebook',
    short: 'World facts',
    definition:
      'Reference entries the AI consults to stay consistent: places, history, and the rules of the world.',
  },
  {
    term: 'Greeting',
    short: 'First message',
    definition:
      'The message a character opens a new chat with. Alternate greetings give each new chat a different start.',
  },
];

export function findTerm(term: string): GlossaryEntry | undefined {
  return GLOSSARY.find((e) => e.term.toLowerCase() === term.toLowerCase());
}

export function GlossaryDialog({ onClose }: { onClose: () => void }) {
  return (
    <div className="glossary-overlay" onClick={onClose} data-testid="glossary-dialog">
      <div
        className="card glossary-dialog"
        role="dialog"
        aria-label="Glossary"
        onClick={(e) => e.stopPropagation()}
      >
        <h2>What do these words mean?</h2>
        <div className="glossary-list">
          {GLOSSARY.map((e) => (
            <div key={e.term} className="glossary-row">
              <span className="glossary-term">{e.term}</span>
              <div>
                <strong>{e.short}</strong>
                <p className="muted">{e.definition}</p>
              </div>
            </div>
          ))}
        </div>
        <button className="primary" onClick={onClose}>
          Close
        </button>
      </div>
    </div>
  );
}

/** Tappable term chip — opens a small dialog with the definition. */
export function GlossaryChip({ term }: { term: string }) {
  const [open, setOpen] = useState(false);
  const entry = findTerm(term);
  if (!entry) return null;
  return (
    <>
      <button
        type="button"
        className="glossary-chip"
        onClick={() => setOpen(true)}
        aria-label={`${entry.term}: ${entry.short}`}
      >
        {entry.term} <span aria-hidden="true">?</span>
      </button>
      {open && (
        <div className="glossary-overlay" onClick={() => setOpen(false)}>
          <div
            className="card glossary-dialog"
            role="dialog"
            aria-label={`${entry.term} definition`}
            onClick={(e) => e.stopPropagation()}
          >
            <h2>
              {entry.term} — {entry.short}
            </h2>
            <p>{entry.definition}</p>
            <button className="primary" onClick={() => setOpen(false)}>
              Close
            </button>
          </div>
        </div>
      )}
    </>
  );
}

/** Inline link that opens the full glossary. */
export function GlossaryLink({ label = 'What do MC, NPC and User mean?' }: { label?: string }) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button type="button" className="glossary-link" onClick={() => setOpen(true)}>
        {label}
      </button>
      {open && <GlossaryDialog onClose={() => setOpen(false)} />}
    </>
  );
}
