# today-continue-write-task-projection-triage (doc-only)

Classification-first triage of why a Home task created via Turn into Task did not appear in Today's Continue during the `write-promotion-device-verification` device pass. The slice was scoped to derive the answer from existing contracts and current implementation, then either close the concern as intentional, queue a follow-up implementation slice if a real gap was found, or document an ambiguity. Conclusion: intentional under the existing contract; documentation clarified.

## 1. What do the existing contracts imply?

- `docs/product/domains/today.md:37` and `:44` list `active Home tasks` among the Continue sources without origin restrictions. Continue is the only Today-tab surface for Focus and active cross-domain work.
- `docs/product/domains/home.md:14` puts `Today Continue ranking, except through exposed active tasks and runs` under "Does Not Own": Home exposes active work but does not own admission policy.
- `docs/product/domains/home.md:75` says "Active protocol runs are first-class Home work. Today and Home summaries should surface them before standalone Home tasks when a run is in progress."
- `docs/product/domains/write.md:62` says task promotion "creates a Home-owned task linked back to the Write note... it must not leave the obligation owned by Write," but does not separately address Today admission.

Combined: active Home tasks (regardless of origin) are Continue-eligible. Within Home, protocol runs precede standalone tasks. There is no documented Write-origin exclusion.

## 2. What does the current implementation do?

- `owlory_xcode/Owlory/Core/Domain/ContinueCandidateRules.swift:40` — `isActiveHomeTaskCandidate` admits any `HomeTask` that is `!isCompleted && !isSkipped && hasDisplayableTitle(title)`. No origin or scheduling gate.
- `owlory_xcode/Owlory/Core/Application/TodayContinueSourceComposer.swift:61` — `sourceOrder` is `[currentFocus, dueTodayTraining, carriedForwardFocus, activeHomeProtocolRun, activeHomeTask, inProgressWriting]`. Protocol runs are walked before standalone tasks.
- `owlory_xcode/Owlory/Core/Application/TodayContinueItemAssembler.swift:43` — applies `ContinueCandidateLimitPolicy.todayDefault` (`maxTotalCount: 5, maxPerDomainCount: 2`) in the walk order via `ContinueCandidateRules.admissionRejection`. Cap-rejected candidates are silently dropped (counts surface only in `ContinuePipelineTrace.AdmissionSummary`).
- `owlory_xcode/Owlory/Core/Application/HomeStore.swift:149` — `promoteWritingNoteToTask` appends the new task to `tasks` and `persistTasks()`. The task is `isCompleted=false`, `isSkipped=false`, has the original note's title, so it satisfies `isActiveHomeTaskCandidate`.

The device run's screenshot 03 (`automation/proofs/write-promotion-device-verification/03-turn-into-task-result.png`) shows two active protocol runs in Home (`Afternoon Routine`, `Evening Routine`). Both pass `isActiveHomeProtocolRunCandidate` and contribute to the `.home` domain count. The per-domain cap is 2, so both protocol runs are admitted before `activeHomeTask` is walked, and the new Standalone Task is correctly rejected with `domainLimitReached(.home)`.

## 3. Is the observed behavior intentional, ambiguous, or a gap?

**Intentional under the existing contract.** The behavior aligns with `today.md` (Home tasks are eligible), `home.md` (protocol runs precede standalone tasks), and `write.md` (Home-owned post-promotion). The only ambiguity was that the cap-induced eviction was implicit — present in the code (`ContinueCandidateLimitPolicy.todayDefault`) but not stated in the contract docs. Closing that documentation gap is what this slice produced.

The user's earlier-stated bias (a tighter rule requiring explicit Focus/schedule/due admission) is a different contract from what is currently documented and shipped. Pursuing it would change Continue admission for every Home task, not just Write-promoted ones, and is therefore out of scope for this Write-promotion-specific triage.

## 4. If a gap, what exact follow-up implementation slice should be queued?

No follow-up implementation slice queued. The current rule is intentional and correctly implemented. If the product owner later decides to tighten Home-task Continue admission (require Focus, schedule, or due state), that should be classified as a separate Continue-admission slice with broader scope. Not queued here because:

- The contract has not changed.
- The current admission policy is consistent with `today.md` and the per-domain cap is intentional protection against any single domain dominating Continue.
- Tightening admission would silently remove existing surfacing of all standalone Home tasks across the app, not just Write-promoted ones.

## 5. What proof level was reached?

`doc-only`. The slice's deliverable is documentation clarifying an existing rule. The required `make test-domain` runs across `today`, `home`, and `write` are regression guards confirming no behavior shift, not proof of a new behavior. `domain-tested` is recorded in `missing_proof_levels` because no new domain rule was introduced that needed direct test coverage; the existing tests for `ContinueCandidateRules.isActiveHomeTaskCandidate`, the source order, and the limit policy still pass and continue to encode the rule.

## Validation

- `python3 automation/context/build_context.py --slice-id today-continue-write-task-projection-triage`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make test-domain DOMAIN=today`
- `make test-domain DOMAIN=home`
- `make test-domain DOMAIN=write`
- `make automation-check`
- `git diff --check`

## Next

No queued follow-up. If product intent later shifts toward a tighter Home-task Continue admission rule, classify it as its own slice with explicit scope and tests. Until then, today.md and write.md document the precedence + cap interaction so future readers do not misread cap-induced eviction as a missing rule.
