# queue-two-stringsdict-portability-slices

## Prompt

> "add slices for the gaps"

Refers to the residual risks recorded in `app-localization-review-drift-check-non-macos-portability` (commit `166f5cb`): Owlory's `Localizable.stringsdict` is still in NeXTSTEP strings-dict format, so the drift tool still needs `plutil` on macOS for this repo today. Linux end-to-end execution remains out of reach without one of two follow-ups.

## What was done

Queue-only update. Appended 2 mutually-supersedable follow-up slices to `automation/queue/slices.json`. No source/test/doc/proof changes.

### Queued (1 slice)

| Slice ID | Pri | Depends on | Approach |
|---|---:|---|---|
| `app-localization-stringsdict-xml-conversion` | 38 | `app-localization-review-drift-check-non-macos-portability` | Convert all 19 `Localizable.stringsdict` files from NeXTSTEP strings-dict syntax to XML plist (`plutil -convert xml1`). After conversion, plistlib parses natively and no shellout is needed. Apple supports both formats at runtime; the conversion is mechanical. |

### Deferred (1 slice, explicit `entry_condition`)

| Slice ID | Pri | Entry condition |
|---|---:|---|
| `app-localization-nextstep-plist-parser` | 28 | `app-localization-stringsdict-xml-conversion` is **not** pursued AND Linux portability is required. If XML conversion lands, this slice can be cancelled — plistlib handles the converted files natively. |

### Why two slices

The two address the same Linux-portability goal via different mechanisms:

- **XML conversion** is a one-time file-format change that the drift tool, plistlib, and other Apple tooling all handle natively. Smaller surface, lower long-term maintenance.
- **NeXTSTEP parser** keeps the source format unchanged and adds a pure-Python fallback in the drift tool. Higher implementation surface but doesn't touch app resources.

Queued the XML conversion as the preferred path. Deferred the NeXTSTEP parser with an entry condition that the XML conversion was rejected; cleanly cancellable if XML conversion lands first.

## Validation

- `python3 -m json.tool automation/queue/slices.json` — passed.
- `make architecture` — passed (no changes outside queue + session note).
- `make automation-check` — 86 tests passed.
- `make pyright` — 0 errors / 0 warnings.
- `python3 automation/supervisor/run_next.py --dry-run` — picks `app-localization-stringsdict-xml-conversion` as next eligible.

## Lane Boundary

`doc-only`. No source, test, or proof artifact changed beyond the queue + this session note.

## Not Claimed

- The Linux portability gap is closed (the two new slices, neither of which has run, would close it).
- XML conversion will succeed without surprises (the conversion is mechanical via `plutil`, but the XCUITest and screenshot baselines must be revalidated to confirm packaging didn't change behavior — that's the implementation slice's job).

## Residual Risk

- `plutil -convert xml1` rewrites the file format and could change byte-level diffs across all 19 locales' stringsdict files. The implementation slice should verify localization-check, the drift tool, and ui-regression DOMAIN=localization remain green after the conversion.
- If Apple ever drops support for the strings-dict format in a future Xcode/iOS release, the XML conversion becomes the only viable path; conversely if the XML format ever gets deprecated for stringsdict in favour of `.xcstrings`, both queued slices become moot.

## Next slice

Supervisor's choice. `app-localization-smaller-width-accessibility-regression` (pri 65) remains the highest-priority queued slice; `app-localization-stringsdict-xml-conversion` (pri 38) is among the lower-priority eligible slices.
