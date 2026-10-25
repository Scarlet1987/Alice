// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import { useEffect, useState } from 'react';
import { api, ApiError } from '../api/client';
import { useAuth } from '../auth/AuthContext';
import { GlossaryLink } from '../components/Glossary';

type ContentZone = 'commons' | 'nsfw' | 'deadDove';

const ZONES: { value: ContentZone; label: string; blurb: string; adult: boolean }[] = [
  {
    value: 'commons',
    label: 'Safe Commons',
    blurb: 'Full guardrails. The cozy default — safe for everyone.',
    adult: false,
  },
  {
    value: 'nsfw',
    label: 'NSFW',
    blurb: 'Adult content with light guardrails. 18+ only.',
    adult: true,
  },
  {
    value: 'deadDove',
    label: 'Dead Dove',
    blurb: 'No app-added guardrails — exactly what it says on the tin. 18+ only.',
    adult: true,
  },
];

export function SetupPage() {
  const { refresh } = useAuth();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [setupToken, setSetupToken] = useState('');
  const [tokenRequired, setTokenRequired] = useState(false);
  const [zone, setZone] = useState<ContentZone>('commons');
  const [adultConfirm, setAdultConfirm] = useState(false);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const zoneDef = ZONES.find((z) => z.value === zone)!;

  useEffect(() => {
    void api
      .get<{ setupTokenRequired?: boolean }>('/api/auth/state')
      .then((s) => setTokenRequired(!!s.setupTokenRequired))
      .catch(() => {});
  }, []);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    if (password.length < 8) return setError('Password must be at least 8 characters.');
    if (password !== confirm) return setError('Passwords do not match.');
    if (tokenRequired && !setupToken.trim()) {
      return setError(
        'Enter the one-time setup code from the desktop app (Settings → Web Server).',
      );
    }
    if (zoneDef.adult && !adultConfirm) {
      return setError('Please confirm you are 18 or older for this zone.');
    }
    setBusy(true);
    try {
      await api.post('/api/auth/setup', {
        username,
        password,
        contentZone: zone,
        ...(setupToken.trim() ? { setupToken: setupToken.trim() } : {}),
      });
      try {
        localStorage.setItem('fpai.contentZone', zone);
      } catch {
        /* non-fatal */
      }
      await refresh();
    } catch (err) {
      if (err instanceof ApiError && err.payload.setupTokenRequired === true) {
        setTokenRequired(true);
      }
      setError(err instanceof ApiError ? err.message : 'Setup failed.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="auth-screen">
      <form className="card auth-card" onSubmit={submit}>
        <h1>Welcome</h1>
        <p className="muted">
          Create your <strong>User</strong> — the account holder. This login
          secures remote access to Front Porch AI from your phone, tablet, or
          another browser.
        </p>
        <label>
          Username
          <input value={username} onChange={(e) => setUsername(e.target.value)} autoFocus required />
        </label>
        <label>
          Password
          <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        </label>
        <label>
          Confirm password
          <input type="password" value={confirm} onChange={(e) => setConfirm(e.target.value)} required />
        </label>
        {tokenRequired && (
          <label>
            Setup code
            <span className="muted"> from desktop Settings → Web Server</span>
            <input
              value={setupToken}
              onChange={(e) => setSetupToken(e.target.value)}
              autoComplete="one-time-code"
              required
            />
          </label>
        )}
        <fieldset className="zone-picker">
          <legend>Content zone</legend>
          <p className="muted small">
            Choose the room you want to live in. You can change this later in
            Settings.
          </p>
          {ZONES.map((z) => (
            <label key={z.value} className={z.value === zone ? 'zone-active' : ''}>
              <input
                type="radio"
                name="contentZone"
                checked={z.value === zone}
                onChange={() => {
                  setZone(z.value);
                  if (!z.adult) setAdultConfirm(false);
                }}
              />
              <span>
                <strong>{z.label}</strong>
                <span className="muted small"> — {z.blurb}</span>
              </span>
            </label>
          ))}
        </fieldset>
        {zoneDef.adult && (
          <label className="adult-confirm">
            <input
              type="checkbox"
              checked={adultConfirm}
              onChange={(e) => setAdultConfirm(e.target.checked)}
              required
            />{' '}
            I confirm I am 18 years or older.
          </label>
        )}
        <p className="muted small">
          The minor-safety boundary stays in place in every zone, no exceptions.
        </p>
        {error && <p className="error">{error}</p>}
        <button className="primary" disabled={busy}>
          {busy ? 'Creating…' : 'Create account'}
        </button>
        <p className="muted small">
          <GlossaryLink label="What does “User” mean here?" />
        </p>
      </form>
    </div>
  );
}
