# app-localization-rtl-sf-symbol-fix

## Prompt

> "start next slice" — execute the supervisor-selected slice `app-localization-rtl-sf-symbol-fix`, which closes HIG-AR-001 + HIG-AR-002 in source by replacing the explicit-directional SF Symbols with auto-mirroring variants.

## What was done

Source-fix slice. Three single-line edits across two files; no logic changes.

### Source changes

| File | Line | Before | After |
|---|---:|---|---|
| `owlory_xcode/Owlory/Features/Today/TodayView.swift` | 566 | `Image(systemName: "chevron.right")` | `Image(systemName: "chevron.forward")` |
| `owlory_xcode/Owlory/Features/Write/WriteView.swift` | 88 | `Image(systemName: "arrow.right.circle")` | `Image(systemName: "arrow.forward.circle")` |
| `owlory_xcode/Owlory/Features/Write/WriteView.swift` | 181 | `Label(L("Advance"), systemImage: "arrow.right.circle")` | `Label(L("Advance"), systemImage: "arrow.forward.circle")` |

Verified by `grep -rn 'chevron\.right\|chevron\.left\|arrow\.right\|arrow\.left' owlory_xcode/Owlory/`: zero matches remaining for any of the explicit-directional SF Symbols in app source.

### Why these changes are correct

Apple HIG documents two SF Symbol naming conventions for directional glyphs:

- `.right` / `.left` (explicit directional): the glyph always points the same way regardless of layout direction. Used when the meaning is geographically right or left.
- `.forward` / `.backward` (semantic / reading-order): auto-mirrors under RTL layout. Used when the meaning is "next" / "previous" / "advance" in the reading-order sense.

All three call sites here describe "next" / "advance" actions (Continue row chevron + writing pipeline advance affordance + advance swipe action). The semantic form is the correct choice under both LTR and RTL.

### Manifest updates

- `automation/proofs/app-localization-rtl-hig-ui-gate-ar/manifest.json`:
  - Moved HIG-AR-001 and HIG-AR-002 from `open_findings` to `in_progress_findings` with `source_fix_confirmed=true`.
  - Appended a `regate_history` entry recording the source change and the next required evidence (post-fix Arabic screenshot).
- `automation/proofs/app-localization-hig-ui-matrix/manifest.json`:
  - Moved HIG-AR-001 and HIG-AR-002 from `open_findings` to `in_progress_findings` with `source_fix_confirmed=true`.
  - Appended a `notes` entry summarising the source fix and pointing at the next slice in the chain.
  - `open_findings` is now 9 (was 11). `in_progress_findings` is now 2 (in addition to HIG-DE-001 already there).

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-rtl-sf-symbol-fix` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `make architecture` — passed.
- `make localization-check` — 19 / 377 / 13.
- `make automation-check` — 71 tests passed.
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-rtl-fix-build CODE_SIGNING_ALLOWED=NO` — exit 0 (warnings only, pre-existing).
- `git diff --check` — clean.
- `python3 -m json.tool` on both manifests — valid.

## Lane Boundary

`build-tested`. xcodebuild compiles cleanly under the deterministic derived-data path. No runtime/UI verification under Arabic launch — that's the next slice (`app-localization-hig-multisurface-screenshot-capture`).

## Residual Risk

- HIG-AR-001 and HIG-AR-002 remain `in-progress` until post-fix Arabic screenshot evidence is preserved under `automation/proofs/`.
- The grep covered `chevron.right/left` and `arrow.right/left` only. If Owlory has custom-drawn directional glyphs, asset-catalog images that imply direction, or decorative artwork that should mirror under RTL, this fix does **not** cover them.
- I did not audit `flipsForRightToLeftLayoutDirection(...)` usage; the source has none (verified by grep), which is correct now that the SF Symbols use the auto-mirroring variants.

## Not Claimed

- HIG-AR-001 or HIG-AR-002 is fully closed (requires post-fix screenshot evidence).
- Arabic is `hig-ui-reviewed`.
- Arabic is `native-reviewed`.
- RTL mirroring is proven on Owlory localized surfaces.
- `screenshot-reviewed`, `device-verified`, or `testflight-verified` for any locale.

## Next slice

`app-localization-hig-multisurface-screenshot-capture` (priority 78) is now eligible. It depends on this slice landing first so the captured Arabic evidence shows the fixed icons (and so HIG-DE-001's reflection-nudge fix is captured alongside).
