.PHONY: architecture fast verify test-domain build-provenance release-check handoff drift-report review-preflight clean-system-metadata verify-app-icons localization-check automation-check

architecture:
	./Tools/architecture-lint.sh

fast:
	./Tools/validate.sh fast

verify:
	./Tools/validate.sh full

handoff:
	./Tools/agent-handoff.sh

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

review-preflight:
	./Tools/review-preflight.sh

build-provenance:
	./Tools/verify-build-provenance.sh

release-check:
	./Tools/verify-build-provenance.sh --require-clean
	./Tools/validate.sh domain runtime

test-domain:
	@if [ -z "$(DOMAIN)" ]; then \
		echo "usage: make test-domain DOMAIN=<today|train|write|career|home|patterns|reminders|runtime|voice>"; \
		exit 2; \
	fi
	./Tools/validate.sh domain "$(DOMAIN)"
