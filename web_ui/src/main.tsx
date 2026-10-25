// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later

import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { HashRouter } from 'react-router-dom';
import { AuthProvider } from './auth/AuthContext';
import { App } from './App';
import { AppErrorBoundary } from './components/AppErrorBoundary';
import { applyChatColors, loadChatColors } from './chatColors';
import { applyReadingSize, loadReadingSize } from './readingSize';
import { applyOled, loadOled, syncOledFromHost } from './oled';
import { syncDetailLevelFromHost } from './detailLevel';
import './styles.css';

// Apply the user's saved chat colors before first paint so bubbles never flash
// the default palette.
applyChatColors(loadChatColors());
applyReadingSize(loadReadingSize());
applyOled(loadOled());
// Then let the host's choices win on fresh devices.
void syncOledFromHost();
void syncDetailLevelFromHost();

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <HashRouter>
      <AppErrorBoundary>
        <AuthProvider>
          <App />
        </AuthProvider>
      </AppErrorBoundary>
    </HashRouter>
  </StrictMode>,
);
