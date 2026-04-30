from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from automation.smoke.running_app_smoke import (
    CommandResult,
    DEFAULT_DESTINATION,
    SmokeConfig,
    find_simulator,
    parse_destination,
    run_smoke,
    runtime_matches
)


class FakeRunner:
    def __init__(
        self,
        repo_root: Path,
        schemes: list[str] = None,
        settings: list[dict] = None,
        devices: dict = None,
        fail_step: str = ""
    ) -> None:
        self.repo_root = repo_root
        self.schemes = schemes if schemes is not None else ["Owlory"]
        self.settings = settings if settings is not None else [self.app_settings()]
        self.devices = devices if devices is not None else self.available_devices()
        self.fail_step = fail_step
        self.calls: list[list[str]] = []

    def __call__(self, argv: list[str], cwd: Path) -> CommandResult:
        self.calls.append(argv)
        if argv[:4] == ["xcodebuild", "-list", "-json", "-project"]:
            return CommandResult(
                argv=argv,
                returncode=0,
                stdout=json.dumps({"project": {"schemes": self.schemes, "targets": ["Owlory"]}})
            )
        if argv[:3] == ["xcodebuild", "-showBuildSettings", "-json"]:
            return CommandResult(argv=argv, returncode=0, stdout=json.dumps(self.settings))
        if argv[:2] == ["xcodebuild", "build"]:
            if self.fail_step == "build":
                return CommandResult(argv=argv, returncode=65, stderr="build failed")
            app_path = self.repo_root / "Build/Products/Debug-iphonesimulator/Owlory.app"
            app_path.mkdir(parents=True, exist_ok=True)
            return CommandResult(argv=argv, returncode=0)
        if argv == ["xcrun", "simctl", "list", "devices", "available", "-j"]:
            return CommandResult(argv=argv, returncode=0, stdout=json.dumps(self.devices))
        if argv[:3] == ["xcrun", "simctl", "boot"]:
            return CommandResult(argv=argv, returncode=0)
        if argv[:3] == ["xcrun", "simctl", "bootstatus"]:
            return CommandResult(argv=argv, returncode=0)
        if argv[:3] == ["xcrun", "simctl", "install"]:
            if self.fail_step == "install":
                return CommandResult(argv=argv, returncode=1, stderr="install failed")
            return CommandResult(argv=argv, returncode=0)
        if argv[:3] == ["xcrun", "simctl", "launch"]:
            if self.fail_step == "launch":
                return CommandResult(argv=argv, returncode=1, stderr="launch failed")
            return CommandResult(argv=argv, returncode=0, stdout="com.raelldottin.owlory: 123")
        if argv[:5] == ["xcrun", "simctl", "io", "TEST-DEVICE", "screenshot"]:
            if self.fail_step == "screenshot":
                return CommandResult(argv=argv, returncode=1, stderr="screenshot failed")
            Path(argv[-1]).parent.mkdir(parents=True, exist_ok=True)
            Path(argv[-1]).write_bytes(b"fake png")
            return CommandResult(argv=argv, returncode=0)
        return CommandResult(argv=argv, returncode=99, stderr=f"unexpected command: {argv}")

    def app_settings(self) -> dict:
        return {
            "target": "Owlory",
            "buildSettings": {
                "PRODUCT_TYPE": "com.apple.product-type.application",
                "WRAPPER_EXTENSION": "app",
                "PRODUCT_BUNDLE_IDENTIFIER": "com.raelldottin.owlory",
                "TARGET_BUILD_DIR": str(self.repo_root / "Build/Products/Debug-iphonesimulator"),
                "FULL_PRODUCT_NAME": "Owlory.app",
                "MARKETING_VERSION": "0.2.0",
                "CURRENT_PROJECT_VERSION": "20260417081904"
            }
        }

    def available_devices(self) -> dict:
        return {
            "devices": {
                "com.apple.CoreSimulator.SimRuntime.iOS-26-3": [
                    {
                        "name": "iPhone 16",
                        "udid": "TEST-DEVICE",
                        "state": "Shutdown",
                        "isAvailable": True
                    }
                ]
            }
        }


class RunningAppSmokeTests(unittest.TestCase):
    def make_config(self, repo_root: Path) -> SmokeConfig:
        project_path = repo_root / "owlory_xcode/Owlory.xcodeproj"
        project_path.mkdir(parents=True)
        return SmokeConfig(
            repo_root=repo_root,
            project_path=project_path,
            scheme="Owlory",
            destination=DEFAULT_DESTINATION,
            configuration="Debug",
            derived_data_path=repo_root / "DerivedData",
            artifacts_dir=repo_root / "artifacts",
            timestamp="20260430T131500Z"
        )

    def test_parse_destination_reads_xcode_key_value_destination(self) -> None:
        parsed = parse_destination("platform=iOS Simulator,name=iPhone 16,OS=26.3.1")

        self.assertEqual("iOS Simulator", parsed["platform"])
        self.assertEqual("iPhone 16", parsed["name"])
        self.assertEqual("26.3.1", parsed["os"])

    def test_runtime_match_accepts_major_minor_runtime_identifier(self) -> None:
        self.assertTrue(runtime_matches("com.apple.CoreSimulator.SimRuntime.iOS-26-3", "26.3.1"))

    def test_find_simulator_uses_destination_name_and_os(self) -> None:
        runner = FakeRunner(Path("/tmp/owlory-test"))
        simulator = find_simulator(parse_destination(DEFAULT_DESTINATION), runner.available_devices())

        self.assertIsNotNone(simulator)
        self.assertEqual("TEST-DEVICE", simulator["udid"])

    def test_success_builds_installs_launches_and_screenshots(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo_root = Path(temp_dir)
            config = self.make_config(repo_root)
            runner = FakeRunner(repo_root)

            result = run_smoke(config, runner=runner)

            self.assertEqual("passed", result["status"])
            self.assertEqual("running-app-smoke", result["proof_level"])
            self.assertEqual("com.raelldottin.owlory", result["xcode"]["bundle_id"])
            self.assertEqual("Booted", result["simulator"]["state"])
            self.assertTrue(Path(result["artifacts"]["screenshot_path"]).exists())
            self.assertEqual(8, result["artifacts"]["screenshot_bytes"])
            self.assertIn(["xcrun", "simctl", "install", "TEST-DEVICE", result["xcode"]["app_path"]], runner.calls)
            self.assertIn(["xcrun", "simctl", "launch", "TEST-DEVICE", "com.raelldottin.owlory"], runner.calls)

    def test_missing_scheme_blocks_before_build(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo_root = Path(temp_dir)
            config = self.make_config(repo_root)
            runner = FakeRunner(repo_root, schemes=["OtherScheme"])

            result = run_smoke(config, runner=runner)

            self.assertEqual("blocked", result["status"])
            self.assertIsNone(result["proof_level"])
            self.assertEqual("xcode-scheme", result["blocked_contract"])
            self.assertFalse(any(call[:2] == ["xcodebuild", "build"] for call in runner.calls))

    def test_non_app_target_blocks_before_build(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo_root = Path(temp_dir)
            config = self.make_config(repo_root)
            runner = FakeRunner(
                repo_root,
                settings=[
                    {
                        "target": "OwloryCoreTests",
                        "buildSettings": {
                            "PRODUCT_TYPE": "com.apple.product-type.bundle.unit-test",
                            "WRAPPER_EXTENSION": "xctest"
                        }
                    }
                ]
            )

            result = run_smoke(config, runner=runner)

            self.assertEqual("blocked", result["status"])
            self.assertEqual("runnable-app-target", result["blocked_contract"])
            self.assertFalse(any(call[:2] == ["xcodebuild", "build"] for call in runner.calls))

    def test_screenshot_failure_does_not_claim_running_app_smoke(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo_root = Path(temp_dir)
            config = self.make_config(repo_root)
            runner = FakeRunner(repo_root, fail_step="screenshot")

            result = run_smoke(config, runner=runner)

            self.assertEqual("failed", result["status"])
            self.assertEqual("build-tested", result["proof_level"])
            self.assertEqual("capture-screenshot", result["failed_stage"])
            self.assertEqual("running-app-smoke", result["blocked_before"])


if __name__ == "__main__":
    unittest.main()
