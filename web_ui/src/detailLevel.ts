// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Web mirror of the desktop detail level (UiSettings.detailLevel).
// Stored per-device in localStorage, synced to the host via /api/settings.

import { api } from './api/client';

export type DetailLevel = 'simple' | 'balanced' | 'advanced';

export const DETAIL_LEVELS: { value: DetailLevel; label: string; description: string }[] = [
  {
    value: 'simple',
    label: 'Simple',
    description: 'Just the essentials. Advanced settings stay out of the way.',
  },
  {
    value: 'balanced',
    label: 'Balanced',
    description: 'The full standard experience. Nothing hidden.',
  },
  {
    value: 'advanced',
    label: 'Advanced',
    description: 'Every knob and fine-tuning option, everywhere.',
  },
];

const KEY = 'fpai.detailLevel';

function valid(v: string | null): v is DetailLevel {
  return v === 'simple' || v === 'balanced' || v === 'advanced';
}

export function loadDetailLevel(): DetailLevel {
  try {
    const raw = localStorage.getItem(KEY);
    if (valid(raw)) return raw;
  } catch {
    /* fall through */
  }
  return 'balanced';
}

export function saveDetailLevel(v: DetailLevel): void {
  try {
    localStorage.setItem(KEY, v);
  } catch {
    /* storage full / disabled — choice just won't persist */
  }
}

/** Pull the host's detailLevel so a fresh device matches the desktop choice. */
export async function syncDetailLevelFromHost(): Promise<void> {
  try {
    const r = await api.get<{ detailLevel?: string }>('/api/settings');
    if (valid(r.detailLevel ?? null)) saveDetailLevel(r.detailLevel as DetailLevel);
  } catch {
    /* offline / old host — keep the local choice */
  }
}

export async function commitDetailLevel(v: DetailLevel): Promise<void> {
  saveDetailLevel(v);
  try {
    await api.post('/api/settings', { detailLevel: v });
  } catch {
    /* offline — the local choice still applies on this device */
  }
}
