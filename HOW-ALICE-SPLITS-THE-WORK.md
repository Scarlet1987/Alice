# How Alice splits the work

> **Coming soon — not yet in a release.** This describes the next version of Alice, in development on this repo's main branch. The latest downloadable release is still v1.5.0-alice7 on the fork; a release from this repo (G1) has not been cut yet. What you read here is what is coming, and feedback now is early feedback, before release.

A plain-language guide to how Alice divides work between your processor,
your graphics card, and your memory — so a new scene stays fast, stable,
and consistent, on everyday hardware.

Alice is a local-first character-chat app. You author the main character,
the AI writes the supporting cast, and everything runs on your machine.
One-time purchase, no cloud, no account. Your characters, worlds, and
chats stay on your machine.

## The short version

- **Full story: saved on your hard drive.** Never loaded whole into
  working memory.
- **Current scene: loaded into working memory.** Plus its characters,
  plus one short recap — if there is a previous scene to recap.
- **Text (story and chat): processor only.** System memory only.
- **Pictures, video, and display: graphics card only.**
- **Voices and background music: processor, shared with text.**
- **Idle engines: asleep.** No background processes. Nothing else loaded.

## 1. How Alice remembers a story

### "When last we left our heroes…"

Each continuing story starts with a short recap, like a TV show's
"Last time on…" — not a replay of the whole story.

- The full story stays in the database on your hard drive
  (`front_porch.db`: characters, sessions, messages, worlds, groups).
- Alice searches that whole saved story on disk, indexed by persons,
  places, things, and names. There is no megabyte cap on the search —
  searching disk is cheap, and the story will grow past any megabyte
  number you pick.
- It then builds **one recap, not a replay**, and feeds working memory
  only: **recap + current scene + its characters**.

### The recap cap: 0–700 tokens

A token is a small chunk of a word — roughly 1 token per 0.75 words,
or about 4 characters.

- **Cap: 0 to 700 tokens, up to about 2.8 KB, about 525 words at most.**
- **700 is a ceiling, not a target.** A brand-new story, or a scene
  that continues straight on, may need no recap at all: 0 tokens.
- At the maximum, the recap is about 4% of the default 16,384-token
  context window.
- If a recap would exceed 700 tokens, older material is summarised
  tighter. The cap does not grow.
- A single recap search looks at the last 20 scenes / about 10 MB of
  recent story; older history comes via entity summaries.

A standard single-spaced Word page is about 500 words, about
650–700 tokens. So the largest recap is just under one such page.

## 2. Text, pictures, voices, music — who does what

| Job | Runs on | Memory it uses |
| --- | --- | --- |
| Text: story, chat, recap | Processor (CPU) | System memory (RAM) |
| Pictures, video, display | Graphics card (GPU) | Graphics memory (VRAM) |
| Voices (text-to-speech, speech-to-text) | Processor, shared with text | System memory |
| Background music | Processor, shared with text and voices | System memory |
| Running the program (orchestration) | Processor, light | System memory |
| Idle engines | Nowhere — asleep, no background processes | None |

"Graphics card only" means the heavy compute is on the graphics card.
The processor still does the light orchestration — loading a model
file from disk, sending commands to the card, checking queues — a few
percent, not compute. Likewise, display still goes through the graphics
card; that is display, not text compute.

### Why text lives on the processor

Text in graphics memory would be faster, but it would steal graphics
memory from pictures. On an 8 GB graphics card, text alone can take
about 70% of graphics memory on a new scene. Pictures need that room.
So text stays on the processor on purpose, and pictures keep the
graphics card.

Text on the processor alone still outruns a fast human typist:

- A typist at 120 words per minute needs about 2.7 tokens per second.
- Processor-only text does about 3–5 tokens per second
  (about 135–225 words per minute).
- Graphics-accelerated text would do about 15–16 tokens per second
  (about 675 words per minute) — faster, but at the cost of graphics
  memory for pictures.

Average reading speed is 200–250 words per minute, so full-speed
processor text is already easy to read as it streams.

### A brand-new scene, in graphics memory

A brand-new scene uses about **70% of graphics memory**
(about 5,730 MB of 8,192 MB), with about 30% spare — healthy, not full,
not empty. The recap is 0 tokens for a new scene, so it adds nothing.
The image engine is present and ready, parked in system memory, and
streams to graphics memory only when an image is actually generated.
If text and image generation ran full at the same instant, they would
try to exceed 100% — so Alice queues them with backpressure instead
of dropping a generation. Stability over raw speed.

## 3. Processor cores: who gets how many

Your processor's cores are its workers. The example machine here has
8 physical cores / 16 threads (threads are virtual — 2 per core).
Counts below are physical cores; double them for threads.

| Job | Cores |
| --- | --- |
| Operating system | 1 |
| Orchestration / user interface | 1 (sustained; 2 briefly on load) |
| Audio: voices | 1 normally, 2 at peak |
| Text | 4–5 (what is left) |
| **Total** | **8** |

Background music, when it is generated and mixed live while voices
are speaking, needs about 2–3 extra cores on top of voices. Playing
a pre-recorded loop is far cheaper, under 1 core.

### Minimum and recommended

- **Minimum: 8 cores.** The machine this was built on. Everything
  works; voices and music share a bit more carefully, and background
  music may be loop-based or queued behind voices at peak moments.
- **Recommended: 12 cores.** For voices + background music at full
  quality at the same time, with no queuing and no compromise.

12 cores is a recommendation beside the base, not a requirement to
run Alice. The base stays 8-core friendly.

## 4. Voices in the base program

A good voice engine ships inside the base program, so audio works out
of the box with no extra download, no cloud voice, and no account.
In settings, beside the voice picker, a "Recommended" label marks the
best voice in the base set. That is guidance, not a requirement — you
can pick another base voice, and audio still works. A better external
voice engine, if one exists, stays beside the base as an optional
upgrade, never as something the base depends on.

Voice models in the base must fit the base program's size cap (below),
so they are the small, good ones — tens of megabytes per voice, not
multi-gigabyte packs.

## 5. How big is the base program?

The base program — the app itself, not your stories, not the AI
models, not your downloads — is about 37–43 megabytes.

- Warning line: **500 MB** — crossing it gets reported, with what is
  driving the growth.
- Hard cap: **2 GB, never.**
- Models and your data never count; they are yours and live separately.

## Feedback

If you have read this and have a thought — a correction, a confusion,
a better split — file it at this repo, or on the Guide & Feedback
page. That is how this guide gets better, and how we learn what
people actually think of the split.

---

Front Porch AI was created by linux4life1. Alice is an independent
edition, and its updates are published from Scarlet1987's repository.

Scarlet1987 — design lead, Alice edition.
Hardware & drivers — Mesa Vulkan drivers (RADV), the open stack
Alice's engines run on; the RX 580 recipe proven by AI Visions Lab.

Follow the white rabbit.
