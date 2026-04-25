# Device Matrix HIG Audit

- Timestamp: 2026-04-24 08:28:42 EDT
- User prompt: "i want a stricter answer with narrow check on device-matrix audit for iPhone SE, iPhone 16, and iPhone 16 Pro Max, plus landscape and larger Dynamic Type"
- Interpretation: Run a stricter manual device audit instead of answering from target metadata alone.

## Plan

1. Confirm target/device support from build settings.
2. Build the app once for simulator use.
3. Launch Owlory on iPhone SE, iPhone 16, and iPhone 16 Pro Max.
4. Check portrait baseline, landscape, and accessibility-sized text.
5. Tie any failures back to the relevant view code.

## Files Inspected

- `owlory_xcode/Owlory/Features/Today/TodayView.swift`
- `owlory_xcode/Owlory/OwloryApp.swift`
- `owlory_xcode/Owlory/RootTabView.swift`
- `docs/workflows/second-brain.md`

## Commands

- `xcrun simctl list devices available | rg 'iPhone (SE \\(3rd generation\\)|16|16 Pro Max)'`
- `xcodebuild -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -showBuildSettings | rg 'TARGETED_DEVICE_FAMILY|SUPPORTED_PLATFORMS|IPHONEOS_DEPLOYMENT_TARGET|PRODUCT_BUNDLE_IDENTIFIER|INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone|SUPPORTS_MACCATALYST|SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD'`
- `xcodebuild -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/Owlory-device-matrix CODE_SIGNING_ALLOWED=NO build`
- `xcrun simctl erase/boot/install/launch ...`
- `xcrun simctl ui <device> content_size ...`
- `xcrun simctl io <device> screenshot ...`

## Results

- Owlory is still an iPhone-only target (`TARGETED_DEVICE_FAMILY = 1`).
- Baseline portrait launch looked acceptable on the audited devices at standard simulator text sizing.
- The stricter matrix failed on accessibility-sized text in portrait on all three audited devices:
  - `iPhone SE (3rd generation)`: Today hero card becomes oversized and dominates the viewport.
  - `iPhone 16`: Today hero and Check-in row visibly break under accessibility-sized text.
  - `iPhone 16 Pro Max`: Check-in row still breaks under accessibility-sized text, even on the largest audited phone.
- Landscape was better than portrait at standard text sizing, but accessibility-sized landscape still clips or crowds the next row on larger phones.
- The implementation evidence matches the screenshots:
  - `TodayView.dashboardHeader` uses dynamic text styles without an adaptive layout fallback.
  - `TodayView.checkInSection` keeps `Label("Check-in") + Spacer() + Text(readinessSummaryLabel)` in one horizontal row, which compresses badly when Dynamic Type grows.

## Outcome

- Strict answer should be: none of the audited iPhone devices currently meet a full HIG-compliant claim across the requested matrix because accessibility-sized portrait layouts still fail.
- No product code changed in this turn.

## Follow-Up Repair

- Continued on 2026-04-25 with a narrow Today presentation fix in `owlory_xcode/Owlory/Features/Today/TodayView.swift`.
- Changed the accessibility-size Today header to use:
  - inline navigation title fallback
  - shorter compact date formatting (`Sat, Apr 25`)
  - shorter hero copy (`Today's plan`)
  - shorter readiness prompt copy (`Check in now`)
  - shorter accessibility-sized check-in label styling
- Updated `docs/product/domains/today.md` so the rule is durable: accessibility layouts may shorten date/header/check-in copy instead of shrinking or capping Dynamic Type.

## Re-Validation

- `xcodebuild -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.3.1' -derivedDataPath /tmp/Owlory-today-a11y-fix-build-5 CODE_SIGNING_ALLOWED=NO build`
- `make test-domain DOMAIN=today`
- `git diff --check`
- Re-ran portrait accessibility screenshots on:
  - `iPhone SE (3rd generation)`
  - `iPhone 16`
  - `iPhone 16 Pro Max`

## Updated Result

- Accessibility portrait is materially improved on all three audited iPhone devices.
- The previous portrait-breaking failure is no longer the honest headline for Today.
- The strict full-matrix claim is still not fully proven because landscape automation was not completed cleanly in this follow-up; Simulator rotation scripting was unreliable in this workspace, so landscape remains unverified rather than silently assumed.

## 2026-04-25 Compact-Height Follow-Up

- Continued on 2026-04-25 with a second Today-specific accessibility pass for compact-height screens in `owlory_xcode/Owlory/Features/Today/TodayView.swift`.
- Added a dedicated compact-height accessibility layout that:
  - reuses the readiness nudge as the primary header message instead of stacking a large redundant hero title above it
  - shortens the compact-height date and semantic text styles
  - shortens mixed readiness copy to `Mixed readiness`
  - keeps the Check-in summary in a smaller stacked treatment
- Updated `docs/product/domains/today.md` so the rule is explicit: compact-height accessibility may collapse the redundant Today hero into the real readiness summary when that is the more truthful and legible presentation.

## Follow-Up Validation

- `xcodebuild -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.3.1' -derivedDataPath /tmp/Owlory-today-landscape-a11y-build-3 CODE_SIGNING_ALLOWED=NO build`
- `make test-domain DOMAIN=today`
- `git diff --check`

## Follow-Up Evidence

- Re-verified `iPhone SE (3rd generation)` in accessibility-sized landscape with a real in-app screenshot after the compact-height pass.
- The SE landscape result is materially better than the original failure: the redundant large Today hero is gone, the readiness message is the primary header content, and the first actionable surfaces remain visible together.
- Attempted the same landscape verification flow on `iPhone 16` and `iPhone 16 Pro Max`, but Simulator window/orientation control remained unreliable on those devices in this workspace. Portrait evidence for those devices is still solid; compact-height landscape evidence outside SE is still incomplete.

## Current Honest Claim

- Today accessibility portrait is materially improved on `iPhone SE (3rd generation)`, `iPhone 16`, and `iPhone 16 Pro Max`.
- Today compact-height accessibility is materially improved and manually evidenced on `iPhone SE (3rd generation)`.
- A strict full landscape matrix claim for all three audited phones is still not fully proven until the larger-phone Simulator rotation path is stabilized or rerun with trustworthy landscape screenshots.

## Remaining Boundary

- Continued trying to capture trusted accessibility-sized landscape screenshots on `iPhone 16` and `iPhone 16 Pro Max`.
- Verified that build/install state is healthy on those simulators and that the compact-height code path compiles/tests cleanly.
- The unresolved issue is Simulator control, not a confirmed Today crash or compile failure:
  - `Simulator` would often boot and install correctly without exposing a stable scriptable window for the larger devices.
  - `Rotate Left` automation remained unreliable outside the SE flow, and several larger-phone captures fell back to portrait or SpringBoard instead of a trustworthy in-app landscape frame.
- Stop condition for this slice: do not upgrade the claim beyond what the evidence supports. The next adjacent slice is specifically simulator-assisted larger-phone landscape verification, not another broad Today refactor.

## 2026-04-25 Larger-Phone Landscape Verification

- Continued the same slice and stabilized the larger-device Simulator path by explicitly persisting `LandscapeLeft` orientation for:
  - `iPhone 16`
  - `iPhone 16 Pro Max`
- Once the live simulator windows were available again, verified Owlory directly in accessibility-sized landscape on both devices instead of relying on stale framebuffer assumptions.
- Verified result:
  - `iPhone 16` compact-height accessibility landscape now keeps the primary Today summary and the Check-in surface visible together.
  - `iPhone 16 Pro Max` compact-height accessibility landscape also keeps the primary Today summary and the Check-in surface visible together, with additional room for the next card.
- This closes the earlier evidence gap. The remaining limitation is tool ergonomics, not an observed Today presentation failure on the audited matrix.

## Updated Honest Claim

- Today accessibility portrait is materially improved on `iPhone SE (3rd generation)`, `iPhone 16`, and `iPhone 16 Pro Max`.
- Today accessibility landscape is now manually verified on `iPhone SE (3rd generation)`, `iPhone 16`, and `iPhone 16 Pro Max` at accessibility-sized text.
- For the audited matrix requested in this slice, Today no longer has the earlier clear HIG-breaking accessibility failure.
