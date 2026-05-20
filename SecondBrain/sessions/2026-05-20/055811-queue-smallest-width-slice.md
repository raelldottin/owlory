# queue-smallest-width-slice

## Prompt

> "add slice for Provision an iPhone SE simulator + add a localization-smallest-width DOMAIN case if that coverage is needed."

User interrupt during the reminders bug investigation; queueing the SE slice first as a quick aside, then resuming the bug fix on `start next slice`.

## What was done

Queue-only update. Appended one blocked slice to `automation/queue/slices.json`. No source/test/doc/proof changes.

### Queued (blocked)

| Slice ID | Pri | Status | Entry condition |
|---|---:|---|---|
| `app-localization-smallest-width-accessibility-regression` | 67 | blocked | An iPhone SE iOS 26.5 simulator is provisioned and named `iPhone SE` on the dev/CI host. The host currently has iPhone 16 / 17 / 17 Pro / 17 Pro Max / 17e / Air sims, but no iPhone SE. |

### Scope summary

Mirrors `app-localization-smaller-width-accessibility-regression` (commit `5209f1f`) but targets iPhone SE — the narrowest currently-shipping iPhone width. Same -only-testing flags as `DOMAIN=localization-smaller-width`, only `-destination` changes. No XCUITest source change; this is a destination-only variant.

### Blocked rationale

The iPhone SE simulator runtime is not provisioned on this machine. Before the slice can run, a contributor or CI maintainer needs to:

```bash
xcrun simctl create 'iPhone SE' <SE-runtime-identifier>
```

The slice's `entry_condition` records this. Status is `blocked` rather than `queued` so `make clean-stop` keeps it parked.

## Validation

- `python3 -m json.tool automation/queue/slices.json` — valid.
- `make automation-check` — 93 tests pass (drift `no drift` + 93 unittests OK).

## Not Claimed

- The slice has been run (it can't — sim isn't provisioned).
- iPhone SE regression coverage exists (it doesn't, this is queueing the slice that would add it).

## Next

Returning to the in-flight `app-reminders-cancel-pending-on-item-completion` slice on the next `start next slice` invocation.
