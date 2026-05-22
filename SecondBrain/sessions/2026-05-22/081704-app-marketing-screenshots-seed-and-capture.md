# app-marketing-screenshots-seed-and-capture

## Prompt

> User showed the App Store Connect screenshot-upload UI with the specific 6.9"/6.7"/6.5"/6.3" resolution buckets and asked for "5-6 portrait screenshots, with real life seeded product data". Order: Today/Continue, Write/Capture, Weekly Digest/reflection, Train, Home. Build Info excluded per their guidance.

## What was done

Generated 5 portrait App Store screenshots at **1320×2868** (iPhone 17 Pro Max native, App Store 6.9" target) of Owlory with realistic seeded data across every primary surface.

### Screenshot set (App Store 6.9" target)

| Order | File | Surface | What it shows |
| ---:| --- | --- | --- |
| 1 | `1-today.png` | Today / Continue dashboard | "Day in progress" card with calibration; Check-in row; Continue list of 3 focus items (Q4 1:1 notes, easy run, dry cleaning) + 2 carried (Strength: legs, Take out recycling). |
| 2 | `2-write.png` | Write / Capture inbox | All three stages: 2 Captures (idea, watch-later), 2 Source Notes (onboarding redesign one-pager, career conversation prep), 1 Permanent insight on deep work. |
| 3 | `3-digest.png` | Weekly Digest + Reflection | Evening Reflection entry, Last Week digest card, Browse Previous Days history (6 entries). Reflection loop in one frame. |
| 4 | `4-train.png` | Train view | Today's planned "Strength: legs (3x8)" with readiness slider + Planned/Completed/Skipped pills + History starting with "5K easy run Completed". |
| 5 | `5-home.png` | Home protocols + tasks | Standalone Tasks (Take out recycling — recurring 7d, Refill dish soap, Schedule dentist, Pay quarterly tax estimate); Protocols (Sunday meal prep). |

All five are 1320×2868 PNG at 8-bit/RGBA. One image set covers Apple's 6.9"/6.7"/6.5" carousels via auto-downscaling.

### Implementation

- **Seed code:** Added `--owlory-ui-seed-marketing` launch arg + `OwloryUITestSupport.seedMarketing()` (DEBUG-only). Reuses the existing `FileTodayEntryRepository` / `FileItemListRepository<T>` pattern that the UI-testing seeds already use, so data lands in the same on-disk format and live stores pick it up.
- **Digest fixture:** Pre-seeds a `WeeklyDigest` for the prior full Monday-Sunday window. `WeeklyDigestCadenceRules.targetWindow` only returns non-nil on Mondays, so without this fixture the Today view's "Last Week" section would not render on any other day of the week. Pre-seeding bypasses the cadence gate for the screenshot run.
- **Capture script:** `automation/smoke/capture_app_store_screenshots.py` boots the iPhone 17 Pro Max simulator, builds Owlory in Debug, installs, launches with the seed args, taps each tab via idb, and writes the 5 PNGs to `automation/proofs/app-store-screenshots/`. Re-running clears the output directory first.

### Realistic seed content (drafted under "I draft, you review")

- **Today focus:** Finalize Q4 1:1 notes for direct reports / 30-min easy run before dinner / Pick up dry cleaning by 6 pm.
- **Prior 6 days of entries** with varied energy/mood/sleep (3-5 range) and one focus item each: sprint retro, strength legs, quarterly tax, onboarding metrics, 5K run, dentist scheduling.
- **Writing notes:** spans capture/source/permanent with bodies a paragraph long each.
- **Training history:** 1 planned + 2 completed (5.2K run + yoga mobility flow) with realistic readiness scores and reflections.
- **Career:** 1 win (shipped onboarding A/B, +12% activation, n=2,134) + 1 impact (3-team migration kickoff alignment).
- **Home:** 1 protocol (Sunday meal prep, 5 steps) + 4 tasks including one recurring weekly task and one with a deadline note.
- **Digest keyInsight:** "Career follow-through climbed with protected morning blocks; energy dipped on the day with the lightest sleep."

Copy is specific enough to look like a real productivity user (named projects, recurrence intervals, completion notes) but role-generic ("direct reports", "manager", "sprint retro") rather than naming actual people.

### Approach

- **Native simulator scale.** Captured at iPhone 17 Pro Max native (1320×2868) so the master matches Apple's largest required resolution exactly. No upscaling, no DPI fuzz.
- **Single seed entrypoint.** All five surfaces are populated by one launch arg + one seed function. Re-running the capture script reseeds deterministically; the iOS sandbox is reset before each run via `resetAppSupport`.
- **idb for tab taps + scrolls.** Logical coords (440×956 → @3x). Tab bar y=920 (just above the home indicator); tab x centers at 44/132/220/308/396 for Today/Train/Write/Career/Home.
- **Digest screenshot trade-off.** The "Last Week" digest renders as a NavigationLink row in the Today view; tapping via idb didn't reliably navigate into `DigestListView`. The captured 3-digest.png shows the digest card + Evening Reflection + Browse Previous Days history — coherent feedback-loop frame. Surfacing the dedicated `DigestListView` would need an XCUITest-driven nav, named as a follow-up.

### Files touched (11 of 12 cap)

1. `owlory_xcode/Owlory/Core/Application/OwloryUITestSupport.swift` — seed marketing arg + function
2. `automation/smoke/capture_app_store_screenshots.py` — reproducible capture driver
3-7. `automation/proofs/app-store-screenshots/{1-today,2-write,3-digest,4-train,5-home}.png`
8. `automation/queue/slices.json`
9. `automation/handoffs/20260522T081704Z-app-marketing-screenshots-seed-and-capture.json`
10. `SecondBrain/INDEX.md`
11. `SecondBrain/sessions/2026-05-22/081704-app-marketing-screenshots-seed-and-capture.md`

## Validation

- `xcodebuild build` — TEST BUILD SUCCEEDED.
- `python3 automation/smoke/capture_app_store_screenshots.py` — manual run; 5 PNGs produced.
- `file *.png` — all 5 confirmed as `PNG image data, 1320 x 2868, 8-bit/color RGBA`.
- `make architecture` — passed.
- `make automation-check` — 124 tests OK.
- `make pyright` — 0 errors (after removing unused os + shutil imports from the capture script).
- `make localization-check` — 19 locales, 386 keys, 13 plural keys (unchanged; no new strings).
- `git diff --check` — clean.

## Lane Boundary

`screenshot-captured`. Swift seed code + Python capture driver + 5 PNG proofs + queue/handoff/INDEX/session. No localization changes. No production code touched outside the DEBUG-gated test support module.

## Not Claimed

- These exact PNGs are what will ship on App Store Connect. The user reviews and uploads; this slice produces the candidates.
- On-device output matches the simulator output byte-for-byte. Real-device rendering may have subtle differences.
- The capture script handles first-run system prompts. If a prompt (location, notifications) intercepts the launch, the script does not dismiss it.

## Next

User said to "ship as-is". Recommended supervisor next pick is `app-accessibility-reduce-motion-helper` (pri 77), continuing the accessibility-survey follow-up chain.
