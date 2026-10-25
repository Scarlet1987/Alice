// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Web mirror of the desktop OLED true-black theme variant (UiSettings.oledBlack).
// Stored per-device in localStorage, synced to the host via /api/settings,
// applied as the `oled` class on <body> so OLED screens can switch pixels off.

import { api } from './api/client';

const KEY = 'fpai.oledBlack';

export function loadOled(): boolean {
  try {
    return localStorage.getItem(KEY) === '1';
  } catch {
    return false;
  }
}

export function saveOled(on: boolean): void {
  try {
    localStorage.setItem(KEY, on ? '1' : '0');
  } catch {
    /* storage full / disabled — choice just won't persist */
  }
}

/** Toggle the `oled` class on <body> (consumed by styles/oled.css). */
export function applyOled(on: boolean): void {
  document.body.classList.toggle('oled', on);
}

/** Pull the host's oledBlack so a fresh device matches the desktop choice. */
export async function syncOledFromHost(): Promise<void> {
  try {
    const r = await api.get<{ oledBlack?: boolean }>('/api/settings');
    if (typeof r.oledBlack === 'boolean') {
      saveOled(r.oledBlack);
      applyOled(r.oledBlack);
    }
  } catch {
    /* offline / old host — keep the local choice */
  }
}

export async function commitOled(on: boolean): Promise<void> {
  saveOled(on);
  applyOled(on);
  try {
    await api.post('/api/settings', { oledBlack: on });
  } catch {
    /* offline — the local choice still applies on this device */
  }
}
