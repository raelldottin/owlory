# hig-testflight-not-required-policy

## Prompt

> "testflight hig proof are not needed automated proofs are acceptible"

## What was done

Doc-only policy clarification. No source change, no test change, no findings reopened, no per-locale state change. The HIG closure that landed earlier today (`app-localization-hig-ui-proof-closure`, 2026-05-18T12:38, commit `a7813a8`/`40ef929`) already passed under this bar; the docs just hadn't stated the policy explicitly — they read as "TestFlight is not claimed" rather than "TestFlight is not required."

### Edits

| File | Change |
|---|---|
| `docs/workflows/localization-hig-ui-completion.md` | Completion Contract paragraph now says **"TestFlight HIG proof is not required to call a locale `hig-ui-reviewed`."** Closure-Status non-claim line reframed to "Not claimed (and not required for the `hig-ui-reviewed` bar): …". |
| `docs/workflows/localization-translation-quality.md` | Apple HIG localized UI review status bullet now states the same policy. HIG multisurface screenshot capture bullet links back to the policy. |
| `automation/proofs/app-localization-hig-ui-matrix/manifest.json` | New `hig_ui_claim_policy` block enumerating `acceptable_proof`, `explicitly_not_required`, and `separate_proof_tracks_still_meaningful`. `not_claimed` entry for TestFlight reframed to "(NOT required by the HIG UI claim policy as of 2026-05-18)". Added a 2026-05-18T19:00:00Z `notes` entry summarizing the clarification. |

### What did NOT change

- Per-locale `hig_ui_reviewed_claim` values (all 19 already `true`).
- The closure capture (`20260518T170353Z-closure-capture/`).
- Findings (still 0 open / 0 in-progress / 11 closed in the matrix).
- The proof-level ladder. `device-verified` and `testflight-verified` remain separate proof tracks that are NOT implied by the HIG UI claim.
- Translation-quality, native-review, or accessibility claims.

## Validation

- `make architecture` — passed.
- `make pyright` — 0 errors / 0 warnings.
- `make localization-check` — 19 / 377 / 13.
- `make automation-check` — passed (now runs pyright + 71 Python tests).
- `python3 -m json.tool automation/proofs/app-localization-hig-ui-matrix/manifest.json` — valid.
- `git diff --check` — clean.

## Lane Boundary

`doc-only`. Policy statement made explicit; no proof artifacts changed; no UI or test changes.

## Not Claimed

- Any locale gained `device-verified` or `testflight-verified` status (those remain separate, untaken proof tracks).
- Translation quality changed.
- The HIG closure was repeated; it remains the one shipped 2026-05-18 in `a7813a8`/`40ef929`.

## Residual Risk

- Future agents reading older session notes may still see language framing TestFlight as a higher tier; the policy block in the matrix and the explicit doc statement are the canonical source of truth going forward.
- The HIG claim is for **scoped simulator surfaces** at iPhone 17 portrait. New surfaces, new locales, smaller iPhone widths, larger Dynamic Type beyond the maintained regression, and physical-device behavior are NOT covered. The HIG claim is bounded; it does not claim "every Owlory pixel is HIG-compliant under every condition."
