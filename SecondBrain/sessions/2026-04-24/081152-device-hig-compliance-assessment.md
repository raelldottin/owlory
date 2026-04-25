# Device HIG Compliance Assessment

## Metadata

- Date: 2026-04-24
- Local Time: 08:11:52 EDT
- Agent: Codex
- Status: done
- Slug: device-hig-compliance-assessment

## User Prompt

```text
which devices is owlory HIG compliant on?
```

## Interpretation

- What the user wants: An honest device-scope answer, not a vague claim that Owlory is or isn't "HIG compliant" in the abstract.
- Scope: Project-supported device families, widget families, and what has actually been validated in this workspace.
- Assumptions: HIG compliance is not a binary certification, so the answer should distinguish supported targets, validated devices, and unproven surfaces.

## Plan

- Step 1: Inspect the project target families and supported platforms.
- Step 2: Spot-check current app builds on representative iPhone devices.
- Step 3: Answer with proven scope rather than overclaiming cross-device compliance.

## Changes

- Modified: `SecondBrain/INDEX.md`
- Created: `SecondBrain/sessions/2026-04-24/081152-device-hig-compliance-assessment.md`
- Inspected: Xcode build settings, widget family support, Apple HIG references for widgets, layout, alerts, buttons, and iOS design.

## Validation

- Commands run: `xcodebuild -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -showBuildSettings`
- Commands run: `xcodebuild -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=17.5' -derivedDataPath /tmp/Owlory-iphone-se-build CODE_SIGNING_ALLOWED=NO build`
- Results: The project targets iPhone only (`TARGETED_DEVICE_FAMILY = 1`) and the iPhone SE (3rd generation) build succeeded in addition to prior iPhone 16-family simulator builds.

## Outcome

- Summary: Owlory can only honestly be discussed as an iPhone app today; native iPad, Mac Catalyst, watchOS, tvOS, and visionOS compliance claims are unsupported by the current target configuration.
- Behavior preserved: No product code changed.
- Risk remaining: Successful builds on iPhone devices do not prove full HIG compliance on every iPhone size or orientation; they only narrow the supported and tested surface.
