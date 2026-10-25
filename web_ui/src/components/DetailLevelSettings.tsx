// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Web mirror of Settings → General → "How much detail do you want?"
// (desktop DetailLevelControl). Persists per-device and syncs to the host.

import { useEffect, useState } from 'react';
import {
  DETAIL_LEVELS,
  commitDetailLevel,
  loadDetailLevel,
  syncDetailLevelFromHost,
  type DetailLevel,
} from '../detailLevel';

export function DetailLevelSettings() {
  const [level, setLevel] = useState<DetailLevel>(() => loadDetailLevel());

  useEffect(() => {
    void syncDetailLevelFromHost().then(() => setLevel(loadDetailLevel()));
  }, []);

  const choose = (v: DetailLevel) => {
    setLevel(v);
    void commitDetailLevel(v);
  };

  const active = DETAIL_LEVELS.find((d) => d.value === level);

  return (
    <section className="card" data-testid="detail-level-card">
      <h3>How much detail do you want?</h3>
      <p className="muted">
        Simple hides advanced knobs and jargon. Advanced reveals everything.
      </p>
      <div className="segmented" role="radiogroup" aria-label="Detail level">
        {DETAIL_LEVELS.map((d) => (
          <button
            key={d.value}
            type="button"
            role="radio"
            aria-checked={d.value === level}
            className={d.value === level ? 'seg-active' : ''}
            onClick={() => choose(d.value)}
          >
            {d.label}
          </button>
        ))}
      </div>
      {active && <p className="muted small">{active.description}</p>}
    </section>
  );
}
