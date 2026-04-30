# Write Promotion Screenshot Proof

## Scope

This proof preserves screenshot evidence for the already flow-verified Write-to-Home-task path:

`Write note -> Turn into Task -> Task / Created / Show -> Home task -> View source note -> original Write note`

It does not prove Today status-only promotion, protocol status-only promotion, real-device behavior, TestFlight behavior, or screenshot-regression automation.

## Evidence

| File | Proves | SHA-256 |
| --- | --- | --- |
| `01-write-note-before-promotion.png` | The source Write note exists before promotion. | `47b05d157ad69edf8fc4b444c37edb2f289cd3720719b0291e528e78fb29c0fd` |
| `02-write-task-created-show.png` | The Write note detail shows `Task`, `Created`, and `Show` after promotion. | `827b15fd598445cc270cfef2fcac0e38f89a8bbb5a58c8b88691d66028e69393` |
| `03-home-task-view-source-note.png` | The promoted Home task detail exposes `View source note`. | `a91f5dde0892272e3c70dff66a1f49b2418d3080c11ff7abe0f7ac6bbf65eb9f` |
| `04-returned-source-write-note.png` | `View source note` returns to the original Write note detail. | `95df67c9de3ea23b6e028c50f301cfde927b7064c6690879fc22e2616140c9e7` |

## Provenance

- Captured during `write-note-promotion-flow-verification` on iPhone 16 simulator, iOS 26.3.1.
- Source flow handoff: `automation/handoffs/20260430T210932Z-write-note-promotion-flow-verification.json`.
- Preserved by this proof slice so future review can inspect the evidence without rerunning the app.

## Validation

```bash
python3 automation/context/build_context.py --slice-id write-promotion-screenshot-proof
python3 automation/supervisor/run_next.py --dry-run
make architecture
make automation-check
git diff --check
```
