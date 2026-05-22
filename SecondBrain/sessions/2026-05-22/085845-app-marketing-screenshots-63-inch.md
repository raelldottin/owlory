# app-marketing-screenshots-63-inch

## Prompt

> "start next slice" (after the 5-slice accessibility-survey chain closed, picking from offered follow-ups)

User selected `Capture 6.3" screenshots` to fill the second App Store Connect screenshot bucket (1206×2622 native).

## What was done

Parameterized `automation/smoke/capture_app_store_screenshots.py` and ran it against the iPhone 17 simulator (6.3" display) to produce the 5 portrait screenshots at 1206×2622 — App Store Connect's exact 6.3" target.

### Script changes

- `parse_args()` now accepts `--device-name` (default `iPhone 17 Pro Max`) and `--output-subdir` (default `automation/proofs/app-store-screenshots`). The default invocation produces the same 6.9" output as before.
- New `DEVICE_LOGICAL_SIZE` table maps device name → (logical width, logical height) in points: iPhone 17 Pro Max 440×956, iPhone 17 / iPhone 17 Pro 402×874.
- New `tab_coords_for(width, height)` helper computes 5 evenly-spaced tab centers with y just above the home indicator (`height - 36`). Works on any iPhone with a 5-tab tab bar.
- New `swipe_up(udid, width, height, times:)` uses the device's logical center + 0.7/0.25 vertical fractions for the scroll endpoints, replacing the hard-coded 220/700/250 from the 6.9" script.

### Captured set

| File | Resolution |
| --- | --- |
| `1-today.png` | 1206×2622 |
| `2-write.png` | 1206×2622 |
| `3-digest.png` | 1206×2622 |
| `4-train.png` | 1206×2622 |
| `5-home.png` | 1206×2622 |

All under `automation/proofs/app-store-screenshots-6.3/`. The existing 6.9" set under `automation/proofs/app-store-screenshots/` is unchanged.

### Approach

- **Parameterize, don't fork.** One script with two args. Defaults preserve the original 6.9" flow; passing `--device-name "iPhone 17" --output-subdir "automation/proofs/app-store-screenshots-6.3"` produces the new set.
- **Compute coordinates from logical size.** Tab and swipe coords are derived from the device's logical width/height. Adding a future device (e.g., a hypothetical iPad bucket) needs only a new `DEVICE_LOGICAL_SIZE` entry.
- **Did NOT rename the existing 6.9" directory.** Apple expects 6.9"/6.7"/6.5" carousels to share a set; the original `automation/proofs/app-store-screenshots/` is the canonical bucket for that group. The 6.3" set lives in its sibling directory.

### Invocation

```bash
# 6.9" (the original, defaults)
python3 automation/smoke/capture_app_store_screenshots.py

# 6.3" (this slice's output)
python3 automation/smoke/capture_app_store_screenshots.py \
    --device-name "iPhone 17" \
    --output-subdir "automation/proofs/app-store-screenshots-6.3"
```

### Files touched (10 of 10 cap)

1. `automation/smoke/capture_app_store_screenshots.py` — parameterized
2–6. `automation/proofs/app-store-screenshots-6.3/{1-today,2-write,3-digest,4-train,5-home}.png`
7. `automation/queue/slices.json` — slice marked done
8. `automation/handoffs/20260522T085845Z-app-marketing-screenshots-63-inch.json`
9. `SecondBrain/INDEX.md`
10. `SecondBrain/sessions/2026-05-22/085845-app-marketing-screenshots-63-inch.md`

## Validation

- `git fetch origin main` — fetched.
- `python3 automation/smoke/capture_app_store_screenshots.py --device-name 'iPhone 17' --output-subdir 'automation/proofs/app-store-screenshots-6.3'` — captured 5 PNGs.
- `file *.png` — all 1206×2622 RGBA.
- `make architecture` — passed.
- `make automation-check` — 124 tests OK.
- `make pyright` — 0 errors.
- `git diff --check` — clean.

## Lane Boundary

`screenshot-captured`. Python script edits + 5 PNG proofs + queue/handoff/INDEX/session. No Swift changes. No localization changes.

## Not Claimed

- These exact PNGs are what will ship on App Store Connect. The user uploads + may re-roll any.
- The tab coordinate calc works on every iPhone simulator. The computed center+bottom-y is reliable for current iPhone shapes; an iPhone SE-style design with a different tab bar position would need explicit overrides.
- On-device rendering matches simulator byte-for-byte.

## Next

Queue empty. Named follow-ups: on-device VoiceOver/Switch Control/Voice Control verification, localization translation-quality reclassification for the 95 new voicecontrol entries, extend input labels to lower-frequency commands, workflow templates in manifest, real third-party repo migration.
