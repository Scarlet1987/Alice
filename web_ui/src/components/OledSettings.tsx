// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Web mirror of Settings → General → "OLED true black"
// (desktop UiSettings.oledBlack). Persists per-device and syncs to the host.

import { useEffect, useState } from 'react';
import { commitOled, loadOled, syncOledFromHost } from '../oled';

export function OledSettings() {
  const [on, setOn] = useState<boolean>(() => loadOled());

  useEffect(() => {
    void syncOledFromHost().then(() => setOn(loadOled()));
  }, []);

  const toggle = (next: boolean) => {
    setOn(next);
    void commitOled(next);
  };

  return (
    <section className="card" data-testid="oled-card">
      <h3>OLED true black</h3>
      <p className="muted">
        Pure-black backgrounds so OLED screens can switch pixels fully off.
        Easier on the eyes in the dark, kinder to the battery.
      </p>
      <label>
        <input
          type="checkbox"
          checked={on}
          onChange={(e) => toggle(e.target.checked)}
          aria-label="OLED true black"
        />{' '}
        OLED true black
      </label>
    </section>
  );
}
