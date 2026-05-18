import json
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace

from automation.smoke import capture_localized_surfaces as harness
from automation.smoke.capture_locale_screenshots import CommandResult


class CaptureLocalizedSurfacesCatalogTests(unittest.TestCase):
    def test_default_catalog_covers_scoped_hig_surfaces(self):
        catalog = harness.build_surface_catalog()
        ids = {surface.id for surface in catalog}

        for required in {
            "today",
            "root-tab-train",
            "root-tab-write",
            "root-tab-career",
            "root-tab-home",
            "build-info",
            "empty-state-today",
            "date-count-plural-today",
        }:
            self.assertIn(required, ids)

    def test_today_surface_has_localized_settled_labels(self):
        catalog = harness.build_surface_catalog()
        today = next(s for s in catalog if s.id == "today")

        self.assertIn("Today", today.settled_assertion_labels)
        self.assertIn("Heute", today.settled_assertion_labels)


class CaptureLocalizedSurfacesArgsTests(unittest.TestCase):
    def test_check_dependencies_only_mode(self):
        args = harness.parse_args(["--check-dependencies"])

        self.assertTrue(args.check_dependencies)
        self.assertFalse(args.capture)
        self.assertFalse(args.dry_run)
        self.assertFalse(args.list_surfaces)

    def test_select_surfaces_default_returns_full_catalog(self):
        catalog = harness.build_surface_catalog()

        self.assertEqual(harness.select_surfaces(catalog, []), catalog)

    def test_select_surfaces_filters_by_id(self):
        catalog = harness.build_surface_catalog()

        selected = harness.select_surfaces(catalog, ["today", "build-info", "not-real"])

        self.assertEqual([s.id for s in selected], ["today", "build-info"])


class CaptureLocalizedSurfacesPlanTests(unittest.TestCase):
    def test_dry_run_plan_enumerates_locale_surface_matrix(self):
        catalog = harness.build_surface_catalog()
        surfaces = [s for s in catalog if s.id in {"today", "root-tab-train"}]
        args = SimpleNamespace(
            udid="SIM-1",
            bundle_id="com.raelldottin.owlory",
            output_dir="/tmp/proof",
            locales=["en", "de"],
        )

        plan = harness.build_plan(args, {"status": "ready"}, surfaces)

        self.assertEqual(plan["captures_planned"], 4)
        self.assertEqual({entry["locale"] for entry in plan["matrix"]}, {"en", "de"})
        self.assertEqual(
            {entry["surface_id"] for entry in plan["matrix"]},
            {"today", "root-tab-train"},
        )


class CaptureLocalizedSurfacesNavigationTests(unittest.TestCase):
    def test_wait_step_records_seconds(self):
        result = harness.run_navigation_step(
            "SIM-1",
            harness.NavigationStep(kind="wait", payload={"seconds": 0}),
            elements=[],
            runner=lambda _: self.fail("runner should not be called for wait step"),
        )

        self.assertEqual(result["status"], "passed")
        self.assertEqual(result["kind"], "wait")

    def test_tap_label_blocks_when_label_missing(self):
        result = harness.run_navigation_step(
            "SIM-1",
            harness.NavigationStep(kind="tap_label", payload={"labels": ["Train"]}),
            elements=[{"AXLabel": "Today"}],
            runner=lambda _: self.fail("runner should not be called when label missing"),
        )

        self.assertEqual(result["status"], "blocked")
        self.assertEqual(result["reason"], "label-not-found")

    def test_tap_label_taps_at_button_center(self):
        recorded = []

        def runner(argv):
            recorded.append(argv)
            return CommandResult(argv=argv, returncode=0)

        result = harness.run_navigation_step(
            "SIM-1",
            harness.NavigationStep(kind="tap_label", payload={"labels": ["Train"]}),
            elements=[
                {"AXLabel": "Train", "frame": {"x": 100, "y": 800, "width": 60, "height": 40}}
            ],
            runner=runner,
        )

        self.assertEqual(result["status"], "passed")
        self.assertEqual(result["tap"], {"x": 130.0, "y": 820.0})
        self.assertEqual(recorded[0][:4], ["idb", "ui", "tap", "--udid"])

    def test_tap_identifier_finds_element_by_ax_identifier(self):
        recorded = []

        def runner(argv):
            recorded.append(argv)
            return CommandResult(argv=argv, returncode=0)

        result = harness.run_navigation_step(
            "SIM-1",
            harness.NavigationStep(kind="tap_identifier", payload={"identifier": "tab.train"}),
            elements=[
                {"AXIdentifier": "tab.train", "frame": {"x": 0, "y": 0, "width": 10, "height": 10}}
            ],
            runner=runner,
        )

        self.assertEqual(result["status"], "passed")
        self.assertEqual(result["tap"], {"x": 5.0, "y": 5.0})

    def test_unknown_step_kind_blocks(self):
        result = harness.run_navigation_step(
            "SIM-1",
            harness.NavigationStep(kind="warp", payload={}),
            elements=[],
            runner=lambda _: self.fail("runner should not be called"),
        )

        self.assertEqual(result["status"], "blocked")
        self.assertEqual(result["reason"], "unknown-step-kind")


class CaptureLocalizedSurfacesGuardTests(unittest.TestCase):
    def test_capture_blocks_when_output_dir_is_not_empty(self):
        with TemporaryDirectory() as temp_dir:
            output_dir = Path(temp_dir) / "proof"
            output_dir.mkdir()
            (output_dir / "stale.png").write_bytes(b"stale")
            args = SimpleNamespace(
                output_dir=str(output_dir),
                locales=["en"],
                udid="SIM-1",
                bundle_id="com.raelldottin.owlory",
                settle_seconds=0,
                min_screenshot_bytes=1,
                allow_simctl_screenshot_fallback=False,
            )

            result = harness.capture_all(
                args,
                surfaces=harness.build_surface_catalog()[:1],
                label_overrides={},
                runner=lambda _: self.fail("runner should not be called"),
            )

            self.assertEqual(result["status"], "blocked")
            self.assertEqual(result["reason"], "output-dir-not-empty")

    def test_load_label_overrides_returns_empty_dict_when_path_empty(self):
        self.assertEqual(harness.load_label_overrides(""), {})

    def test_load_label_overrides_reads_locale_specific_labels(self):
        with TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "overrides.json"
            path.write_text(
                json.dumps({"today": ["Сегодня", "Idag"], "ignored": "wrong-type"}),
                encoding="utf-8",
            )

            overrides = harness.load_label_overrides(str(path))

            self.assertEqual(overrides["today"], ["Сегодня", "Idag"])
            self.assertNotIn("ignored", overrides)


if __name__ == "__main__":
    unittest.main()
