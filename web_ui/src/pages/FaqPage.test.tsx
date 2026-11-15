// Copyright (C) 2026 Front Porch AI
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Alice FAQ guard (web port of test/ui/alice/v9/alice_v9_faq_test.dart):
// the FAQ route renders the policy questions, the draft guide, the
// suggestion box, and the running file. A submitted request is saved
// to the file in localStorage; the jump mark and the fresh-file
// confirm are covered too.

import { act } from 'react-dom/test-utils';
import { createRoot, type Root } from 'react-dom/client';
import { createElement } from 'react';
import { MemoryRouter } from 'react-router-dom';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { FEEDBACK_STORAGE_KEY } from '../lib/feedbackFile';
import { FaqPage } from './FaqPage';

let container: HTMLDivElement;
let root: Root;

async function open() {
  await act(async () => {
    root.render(
      createElement(
        MemoryRouter,
        null,
        createElement(FaqPage),
      ),
    );
  });
}

function button(label: string): HTMLButtonElement | undefined {
  return [...container.querySelectorAll('button')].find(
    (b) => b.textContent?.trim() === label,
  );
}

function fieldByPlaceholder(placeholder: string): HTMLInputElement | HTMLTextAreaElement {
  const el = container.querySelector(
    `[placeholder="${placeholder}"]`,
  ) as HTMLInputElement | HTMLTextAreaElement | null;
  if (el === null) throw new Error(`no field with placeholder ${placeholder}`);
  return el;
}

async function type(
  el: HTMLInputElement | HTMLTextAreaElement,
  value: string,
) {
  const setter = Object.getOwnPropertyDescriptor(
    el instanceof HTMLTextAreaElement
      ? HTMLTextAreaElement.prototype
      : HTMLInputElement.prototype,
    'value',
  )?.set;
  await act(async () => {
    setter?.call(el, value);
    el.dispatchEvent(new Event('input', { bubbles: true }));
  });
}

async function click(el: HTMLElement) {
  await act(async () => {
    el.click();
  });
}

async function submitWhat(what: string) {
  await type(
    fieldByPlaceholder('e.g. Replies stop mid-sentence on long chats'),
    what,
  );
  const submit = button('Add it to the file');
  expect(submit).toBeDefined();
  await click(submit!);
}

beforeEach(() => {
  (globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true;
  window.localStorage.removeItem(FEEDBACK_STORAGE_KEY);
  container = document.createElement('div');
  document.body.appendChild(container);
  root = createRoot(container);
});

afterEach(() => {
  act(() => root.unmount());
  container.remove();
  window.localStorage.removeItem(FEEDBACK_STORAGE_KEY);
  vi.restoreAllMocks();
});

describe('the FAQ page', () => {
  it('renders the policy, the guide, the suggestion box, and the running file', async () => {
    await open();
    expect(container.textContent).toContain('Questions, complaints & requests');
    expect(container.textContent).toContain('Is Alice free?');
    expect(container.textContent).toContain('New here? Start with these');
    expect(container.textContent).toContain('Start with the basics');
    expect(container.textContent).toContain('Coming from SillyTavern');
    expect(container.textContent).toContain('The suggestion box');
    expect(container.textContent).toContain('The running file');
    expect(container.textContent).toContain('Nothing collected yet');
  });

  it('submitting a request adds it to the file', async () => {
    await open();
    await submitWhat('Replies stop mid-sentence on long chats');
    expect(container.textContent).toContain(
      "Added — it's in the file, under its category.",
    );
    expect(container.textContent).toContain('Chat & replies — 1 entry');
    expect(container.textContent).toContain(
      '1. [Request] Replies stop mid-sentence on long chats',
    );
    // The page saved the entry: the stored markdown is the file.
    const stored = window.localStorage.getItem(FEEDBACK_STORAGE_KEY);
    expect(stored).not.toBeNull();
    expect(stored).toContain('# Alice — Feedback File');
    expect(stored).toContain('Replies stop mid-sentence on long chats');
  });

  it('empty What shows the error and saves nothing', async () => {
    await open();
    const submit = button('Add it to the file');
    expect(submit).toBeDefined();
    await click(submit!);
    expect(container.textContent).toContain(
      'The file needs the What — everything else can be filled in as best you can.',
    );
    expect(window.localStorage.getItem(FEEDBACK_STORAGE_KEY)).toBeNull();
  });

  it('out-of-beta mark reveals the done-list and saves the mark', async () => {
    await open();
    const doneItem =
      'Everything Alice ships with works — every feature in the box does what it says.';
    expect(container.textContent).not.toContain(doneItem);
    const mark = button('Out of beta — the v2.0 jump');
    expect(mark).toBeDefined();
    await click(mark!);
    expect(container.textContent).toContain('The out-of-beta test');
    expect(container.textContent).toContain(doneItem);
    const stored = window.localStorage.getItem(FEEDBACK_STORAGE_KEY);
    expect(stored).toContain('OUT OF BETA');
  });

  it('removing an entry drops it from the file', async () => {
    await open();
    await submitWhat('Replies stop mid-sentence on long chats');
    expect(container.textContent).toContain('Chat & replies — 1 entry');
    const remove = button('Remove this entry');
    expect(remove).toBeDefined();
    await click(remove!);
    expect(container.textContent).toContain('Nothing collected yet');
    const stored = window.localStorage.getItem(FEEDBACK_STORAGE_KEY);
    expect(stored).not.toContain('Replies stop mid-sentence');
  });

  it('Start a fresh file clears the entries after confirming', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(true);
    await open();
    await submitWhat('Replies stop mid-sentence on long chats');
    expect(container.textContent).toContain('Chat & replies — 1 entry');
    const fresh = button('Start a fresh file');
    expect(fresh).toBeDefined();
    await click(fresh!);
    expect(container.textContent).toContain('Nothing collected yet');
    expect(window.localStorage.getItem(FEEDBACK_STORAGE_KEY)).toBeNull();
  });

  it('Copy puts the markdown on the clipboard', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.defineProperty(window.navigator, 'clipboard', {
      value: { writeText },
      configurable: true,
    });
    await open();
    await submitWhat('Replies stop mid-sentence on long chats');
    const copy = button('Copy the file');
    expect(copy).toBeDefined();
    await click(copy!);
    expect(writeText).toHaveBeenCalledTimes(1);
    expect(writeText.mock.calls[0][0]).toContain('# Alice — Feedback File');
    expect(container.textContent).toContain('Copied — ready to paste or send.');
  });
});
