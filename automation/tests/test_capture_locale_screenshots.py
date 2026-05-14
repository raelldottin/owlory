import unittest
from types import SimpleNamespace
from tempfile import TemporaryDirectory

from automation.smoke import capture_locale_screenshots as screenshots


class CaptureLocaleScreenshotsTests(unittest.TestCase):
    def test_dependency_report_blocks_when_idb_client_missing(self):
        report = screenshots.build_dependency_report(
            which=lambda tool: "/usr/local/bin/idb_companion" if tool == "idb_companion" else None
        )

        self.assertEqual(report["status"], "blocked")
        self.assertEqual([item["tool"] for item in report["missing"]], ["idb"])
        self.assertIn("python3 -m pip install --user fb-idb", report["missing"][0]["remediation"][0])

    def test_dependency_report_ready_when_both_tools_exist(self):
        report = screenshots.build_dependency_report(
            which=lambda tool: f"/usr/local/bin/{tool}"
        )

        self.assertEqual(report["status"], "ready")
        self.assertEqual(report["missing"], [])

    def test_detects_notification_prompt(self):
        elements = [
            {"AXLabel": "Today"},
            {"AXLabel": "“Owlory” Would Like to Send You Notifications"},
        ]

        self.assertTrue(screenshots.contains_known_prompt(elements))

    def test_finds_dismiss_button_center(self):
        elements = [
            {
                "AXLabel": "Don’t Allow",
                "frame": {"x": 12, "y": 40, "width": 100, "height": 44},
            }
        ]

        self.assertEqual(
            screenshots.find_button(elements, screenshots.KNOWN_DISMISS_LABELS),
            (62.0, 62.0),
        )

    def test_idb_command_targets_udid_first(self):
        self.assertEqual(
            screenshots.idb_command("SIM-1", ["ui", "describe-all"]),
            ["idb", "ui", "describe-all", "--udid", "SIM-1"],
        )

    def test_idb_command_places_udid_before_positional_arguments(self):
        self.assertEqual(
            screenshots.idb_command("SIM-1", ["screenshot", "/tmp/out.png"]),
            ["idb", "screenshot", "--udid", "SIM-1", "/tmp/out.png"],
        )

    def test_capture_blocks_when_output_dir_is_not_empty(self):
        with TemporaryDirectory() as temp_dir:
            output_dir = f"{temp_dir}/proof"
            args = SimpleNamespace(
                output_dir=output_dir,
                locales=["en"],
                udid="SIM-1",
                bundle_id="com.raelldottin.owlory",
                settle_seconds=0,
                min_screenshot_bytes=1,
                allow_simctl_screenshot_fallback=False,
            )
            import pathlib

            pathlib.Path(output_dir).mkdir()
            pathlib.Path(output_dir, "stale.png").write_bytes(b"stale")

            result = screenshots.capture_all(args, runner=lambda _: self.fail("runner should not be called"))

            self.assertEqual(result["status"], "blocked")
            self.assertEqual(result["reason"], "output-dir-not-empty")


if __name__ == "__main__":
    unittest.main()
