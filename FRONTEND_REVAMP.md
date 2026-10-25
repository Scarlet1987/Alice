# Front-End Revamp — `kavi/gui-revamp`

A full front-end re-engineering of Front Porch AI, designed around one goal:
**more user creativity**. Every screen was rebuilt around the idea that the
user authors the main character and the world, and the app handles the rest.

**Live interactive preview:**
https://muse.ai/s/front-porch-gui-preview-xpxk61rlo1xvxuxj

> The preview is the design source of truth while feedback is open. Approved
> preview changes are folded into this branch in passes; a Linux executable
> build follows once the design settles.

## Design language

- **Palette:** teal and white with touches of blue and pink, on deep dark
  surfaces. (True-black OLED ground still under review.)
- **Guiding rule:** *if it doesn't make sense to the user, the user will
  either complain or ignore it.* Clarity isn't polish — it's the whole game.
- **Detail control:** Simple / Balanced / Advanced segmented control with
  progressive disclosure **in both directions** — the mode sets a default
  density, never a cage. Any section expands or collapses regardless of mode.
- **Plain-English glossary** built into the app: MC = main character,
  NPC = non-playable character, User = account holder.

## What's new

**Creator (restructured).** The old single creator is now three surfaces:
- *User tab* — the real you: name, birthday, a 300-word bio ("how other
  users see you"), persona name, pronouns. Nothing about the MC here.
- *Main Character board* — all protagonist depth in collapsible sections:
  Kardashev scale, gear loadout, personality, appearance & body, greeting /
  voice / dialogue, world block, model features.
- *NPC tab* — "The AI writes your NPCs — you just give the spark."
  Name (or let the AI name them), role, one-line concept, relationship to MC.

**Kardashev scale system.** A mandatory, radio-behavior scale selector
(Type 0 → I → II → III → Beyond) that locks on save. The gear loadout
(offensive / defensive / clothing) is live-checked against the scale, with
fits / over-scale warnings. Golden rule, always on: the scale stops at
quantum entanglement — no god-tier absolutes; nothing grows in a vacuum.

**Content zones.** Chosen at account creation, 18+ verified for the adult
two, changeable later: **Safe Commons** (full guardrails, default),
**NSFW** (.5 guardrails), **Dead Dove** (user-loaded models, 0 app-added
rails). One invariant across every zone: no sexual content involving minors.

**Dead Dove, rebuilt as negotiated limits.** Framed as consensual
non-consent: selecting the zone shows a disclaimer (AI-generated characters;
your ticked boxes plus the one floor are the only rules), then a five-step
flow — what each colour means, your fantasy & stop word, a searchable
**Top 100** fetish list ranked by real-world commonality, a separate
**story & content** checklist (death, conflict, tone, stakes, endings…),
and a **Compile list** button that produces your red / yellow / green
summary. That compiled list becomes the model's instructions. Non-binary
character support is built into the creator (gender identity selector,
they/them + custom pronouns).

**Engines & memory.** Text (KoboldCpp) + image engines run together: LLM
context/KV in system RAM, active compute in VRAM, image weights parked in
RAM and streamed to VRAM during generation. *Engine resources* settings
page with VRAM/RAM auto-detect; stability over raw speed — generations
queue with backpressure, never drop. A **Connect** button starts the
backend listener; **Disconnect** (or closing the app) stops it so nothing
sits on RAM/VRAM idle.

**Also in:** adjustable memory-checkpoint timer (default 30 min, nudges you
to pin context to your MC's card — never auto-writes), Models hub (Images +
Voice catalogs, user-addable, synced to chat), per-character voice switches,
world hierarchy (Stage → Universe → Planet → Continent → City → district)
with a lore book built from save state.

## Status

Active design review via the preview link above. Backend wiring follow-ups
(GenerationPolicy hooks, live queue-depth API, model-swap queuing,
context paging) land with the executable build after feedback closes.
