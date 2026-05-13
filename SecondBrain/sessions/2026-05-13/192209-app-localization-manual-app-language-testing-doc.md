# app-localization-manual-app-language-testing-doc

## Summary

Added manual per-app language testing instructions for newer iOS and TestFlight/device localization review.

The docs now distinguish:

- manual/TestFlight review through `Settings > Apps > Owlory > Language`
- fallback setup through `Settings > General > Language & Region > Add Language`
- automated locale smoke through launch arguments (`-AppleLanguages` and `-AppleLocale`) via the smoke runner

## Files

- `docs/workflows/validation.md`
- `docs/workflows/localization-translation-quality.md`
- `docs/workflows/ui-testing-hygiene.md`
- `automation/queue/slices.json`
- `automation/handoffs/20260513T232209Z-app-localization-manual-app-language-testing-doc.json`

## Validation

```bash
python3 automation/context/build_context.py --slice-id app-localization-manual-app-language-testing-doc
python3 automation/supervisor/run_next.py --dry-run
python3 -m json.tool automation/queue/slices.json
```

Apple fallback path checked against:

```text
https://support.apple.com/en-us/109358
```

## Residual Risk

This is docs-only. It does not prove translation quality, layout correctness, packaged-resource behavior, or TestFlight localization behavior.
