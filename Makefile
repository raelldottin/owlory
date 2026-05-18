.PHONY: architecture fast verify test-domain ui-smoke ui-smoke-proof ui-regression build-provenance release-preflight release-check handoff clean-stop drift-report review-preflight clean-system-metadata verify-app-icons localization-check localization-screenshot-idb-check localization-multisurface-screenshot-idb-check automation-check

architecture:
	./Tools/architecture-lint.sh

fast:
	./Tools/validate.sh fast

verify:
	./Tools/validate.sh full

handoff:
	./Tools/agent-handoff.sh

clean-stop:
	python3 Tools/clean-stop-check.py

automation-check:
	python3 -m unittest discover -s automation/tests -p 'test_*.py'

drift-report:
	./Tools/drift-report.sh

clean-system-metadata:
	./Tools/clean-system-metadata.sh

verify-app-icons:
	./Tools/verify-app-icons.sh

localization-check:
	./Tools/localization-parity.sh

localization-screenshot-idb-check:
	python3 automation/smoke/capture_locale_screenshots.py --check-dependencies

localization-multisurface-screenshot-idb-check:
	python3 automation/smoke/capture_localized_surfaces.py --check-dependencies

review-preflight:
	./Tools/review-preflight.sh

ui-smoke:
	@DESTINATION="$${OWLORY_XCODE_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.5}"; \
	echo "Running Owlory UI smoke on $$DESTINATION"; \
	xcodebuild test \
		-project owlory_xcode/Owlory.xcodeproj \
		-scheme Owlory \
		-configuration Debug \
		-destination "$$DESTINATION" \
		-derivedDataPath /tmp/owlory-ui-smoke-derived-data \
		-only-testing:OwloryUITests/OwloryUITests

ui-smoke-proof: ui-smoke
	python3 automation/smoke/extract_ui_smoke_screenshots.py

ui-regression:
	@DESTINATION="$${OWLORY_XCODE_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.5}"; \
	case "$(DOMAIN)" in \
		"") ONLY_TESTING="-only-testing:OwloryUITests/TodayContinueRegression -only-testing:OwloryUITests/WriteCaptureRegression -only-testing:OwloryUITests/TrainRegression -only-testing:OwloryUITests/HomeProtocolRegression -only-testing:OwloryUITests/HomeProtocolRunStepRegression -only-testing:OwloryUITests/LocalizationLayoutRegression -only-testing:OwloryUITests/LocalizationAccessibilityRegression"; LABEL="all regression classes" ;; \
		today) ONLY_TESTING="-only-testing:OwloryUITests/TodayContinueRegression"; LABEL="Today Continue regression" ;; \
		write) ONLY_TESTING="-only-testing:OwloryUITests/WriteCaptureRegression"; LABEL="Write capture inbox regression" ;; \
		train) ONLY_TESTING="-only-testing:OwloryUITests/TrainRegression"; LABEL="Train active/history regression" ;; \
		home) ONLY_TESTING="-only-testing:OwloryUITests/HomeProtocolRegression -only-testing:OwloryUITests/HomeProtocolRunStepRegression"; LABEL="Home protocol regression (template archive/restore + run step progression)" ;; \
		localization) ONLY_TESTING="-only-testing:OwloryUITests/LocalizationLayoutRegression -only-testing:OwloryUITests/LocalizationAccessibilityRegression"; LABEL="Localization layout + accessibility regression (en, de, ar, zh-Hans launch-shell + Dynamic Type accessibility XL + tab label/touch-target checks)" ;; \
		*) echo "usage: make ui-regression [DOMAIN=today|write|train|home|localization]"; exit 2 ;; \
	esac; \
	echo "Running Owlory UI regression batch ($$LABEL) on $$DESTINATION"; \
	xcodebuild test \
		-project owlory_xcode/Owlory.xcodeproj \
		-scheme Owlory \
		-configuration Debug \
		-destination "$$DESTINATION" \
		-derivedDataPath /tmp/owlory-ui-regression-derived-data \
		$$ONLY_TESTING

build-provenance:
	./Tools/verify-build-provenance.sh

release-preflight:
	./Tools/release-preflight.sh

release-check: release-preflight
	./Tools/validate.sh domain runtime

test-domain:
	@if [ -z "$(DOMAIN)" ]; then \
		echo "usage: make test-domain DOMAIN=<today|train|write|career|home|patterns|reminders|runtime|voice>"; \
		exit 2; \
	fi
	./Tools/validate.sh domain "$(DOMAIN)"
