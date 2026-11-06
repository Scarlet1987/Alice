# Combined preview v9 — fixes, 2026-11-05

`alice-combined-preview-v9-fixes-2026-11-05.html` — the approved combined v9 preview, with the visual-walkthrough fixes applied. Preview only, open in Firefox. No Dart until approved.

Fixes in this copy (all pushed to Rawhide, commits 48ef850..94f7e00):
- Round 5: readable text — black text on pale inputs, hint black 60%
- Round 5b: dropdown popup — pale background, black menu items
- Round 6: Pocket narrowed to 1100px, centred
- Round 7: headings centred in full-width green bars, every button centred, green backgrounds kept
- Round 8: empty Cover Flow shape — 3 outline placeholder cards, centre "+new / create your first", no fake names, honest empty text stays
- Round 9b: asset box — one browse, one check, one drop in ("Drop an asset here, or use browse below."); native file input hidden in preview only
- Round 10: Pocket aligned with Stage / Current Char above it (same centre line, same left/right edges)

Source of truth for the fixes is the Dart code in `lib/ui/alice/v9/` on branch Rawhide.
