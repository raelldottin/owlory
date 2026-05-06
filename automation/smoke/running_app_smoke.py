from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Optional


DEFAULT_DESTINATION = "platform=iOS Simulator,name=iPhone 16,OS=26.3.1"
RUNNING_APP_PROOF_LEVEL = "running-app-smoke"
BUILD_PROOF_LEVEL = "build-tested"


@dataclass
class CommandResult:
    argv: list[str]
    returncode: int
    stdout: str = ""
    stderr: str = ""


@dataclass
class SmokeConfig:
    repo_root: Path
    project_path: Path
    scheme: str
    destination: str
    configuration: str
    derived_data_path: Path
    artifacts_dir: Path
    timestamp: str
    locale: str = ""
    apple_locale: str = ""


CommandRunner = Callable[[list[str], Path], CommandResult]


def parse_args() -> argparse.Namespace:
    repo_root = Path(__file__).resolve().parents[2]
    default_artifacts = Path("/tmp/owlory-running-app-smoke")
    parser = argparse.ArgumentParser(
        description="Build, install, launch, and screenshot Owlory on a simulator."
    )
    parser.add_argument("--repo-root", default=str(repo_root))
    parser.add_argument("--project", default="owlory_xcode/Owlory.xcodeproj")
    parser.add_argument("--scheme", default="Owlory")
    parser.add_argument(
        "--destination",
        default=os.environ.get("OWLORY_XCODE_DESTINATION", DEFAULT_DESTINATION)
    )
    parser.add_argument("--configuration", default="Debug")
    parser.add_argument(
        "--derived-data-path",
        default=str(default_artifacts / "DerivedData")
    )
    parser.add_argument(
        "--artifacts-dir",
        default=str(default_artifacts / "artifacts")
    )
    parser.add_argument(
        "--locale",
        default="",
        help="Optional Apple language code to pass at launch, such as en, es, ar, or zh-Hans."
    )
    parser.add_argument(
        "--apple-locale",
        default="",
        help="Optional AppleLocale launch value. Defaults to --locale when omitted."
    )
    parser.add_argument("--output", help="Optional path for the result JSON. Defaults to stdout.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = Path(args.repo_root).resolve()
    project_path = Path(args.project)
    if not project_path.is_absolute():
        project_path = repo_root / project_path

    config = SmokeConfig(
        repo_root=repo_root,
        project_path=project_path,
        scheme=args.scheme,
        destination=args.destination,
        configuration=args.configuration,
        derived_data_path=Path(args.derived_data_path),
        artifacts_dir=Path(args.artifacts_dir),
        timestamp=timestamp(),
        locale=args.locale,
        apple_locale=args.apple_locale or args.locale
    )

    result = run_smoke(config)
    output = json.dumps(result, indent=2, sort_keys=True)
    if args.output:
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(output + "\n", encoding="utf-8")
    else:
        print(output)

    return 0 if result["status"] == "passed" else 1


def run_smoke(
    config: SmokeConfig,
    runner: CommandRunner = None
) -> dict[str, Any]:
    if runner is None:
        runner = default_runner

    result = base_result(config)
    project_contract = check_project_contract(config, result, runner)
    if project_contract is None:
        return result

    simulator = resolve_simulator(config, result, runner)
    if simulator is None:
        return result

    build_result = run_step(
        result,
        "build-app",
        [
            "xcodebuild",
            "build",
            "-project",
            str(config.project_path),
            "-scheme",
            config.scheme,
            "-configuration",
            config.configuration,
            "-destination",
            config.destination,
            "-derivedDataPath",
            str(config.derived_data_path),
            "-quiet"
        ],
        config.repo_root,
        runner
    )
    if build_result.returncode != 0:
        return fail_result(
            result,
            stage="build-app",
            reason="xcodebuild build failed before a runnable app artifact was proven.",
            proof_level=None
        )

    app_path = project_contract["app_path"]
    if not Path(app_path).exists():
        return fail_result(
            result,
            stage="locate-built-app",
            reason=f"xcodebuild succeeded but the expected app bundle was not found at {app_path}.",
            proof_level=BUILD_PROOF_LEVEL
        )

    if config.locale:
        localized_resources = check_localization_resources(Path(app_path), config.locale)
        if localized_resources is None:
            return fail_result(
                result,
                stage="check-localization-resources",
                reason=(
                    f"Built app bundle is missing required localization resources for "
                    f"{config.locale}.lproj."
                ),
                proof_level=BUILD_PROOF_LEVEL
            )
        result["artifacts"]["localized_resources"] = localized_resources

    install_result = run_step(
        result,
        "install-app",
        ["xcrun", "simctl", "install", simulator["udid"], app_path],
        config.repo_root,
        runner
    )
    if install_result.returncode != 0:
        return fail_result(
            result,
            stage="install-app",
            reason="simctl install failed after the app built.",
            proof_level=BUILD_PROOF_LEVEL
        )

    launch_command = ["xcrun", "simctl", "launch", simulator["udid"], project_contract["bundle_id"]]
    launch_command.extend(locale_launch_arguments(config))
    launch_result = run_step(
        result,
        "launch-app",
        launch_command,
        config.repo_root,
        runner
    )
    if launch_result.returncode != 0:
        return fail_result(
            result,
            stage="launch-app",
            reason="simctl launch failed after the app installed.",
            proof_level=BUILD_PROOF_LEVEL
        )

    screenshot_path = config.artifacts_dir / config.timestamp / screenshot_filename(config)
    screenshot_path.parent.mkdir(parents=True, exist_ok=True)
    screenshot_result = run_step(
        result,
        "capture-screenshot",
        ["xcrun", "simctl", "io", simulator["udid"], "screenshot", str(screenshot_path)],
        config.repo_root,
        runner
    )
    if screenshot_result.returncode != 0:
        return fail_result(
            result,
            stage="capture-screenshot",
            reason="simctl screenshot failed after launch; running-app-smoke proof requires a screenshot artifact.",
            proof_level=BUILD_PROOF_LEVEL
        )
    if not screenshot_path.exists() or screenshot_path.stat().st_size == 0:
        return fail_result(
            result,
            stage="capture-screenshot",
            reason="simctl screenshot exited successfully but no non-empty screenshot artifact was produced.",
            proof_level=BUILD_PROOF_LEVEL
        )

    result["status"] = "passed"
    result["proof_level"] = RUNNING_APP_PROOF_LEVEL
    result["blocked_before"] = None
    result["reason"] = "App built, installed, launched, and produced a screenshot artifact."
    result["artifacts"]["screenshot_path"] = str(screenshot_path)
    result["artifacts"]["screenshot_bytes"] = screenshot_path.stat().st_size
    return result


def check_project_contract(
    config: SmokeConfig,
    result: dict[str, Any],
    runner: CommandRunner
) -> Optional[dict[str, str]]:
    if not config.project_path.exists():
        return block_result(
            result,
            contract="xcode-project",
            reason=f"Xcode project does not exist at {config.project_path}."
        )

    list_result = run_step(
        result,
        "check-xcode-project-list",
        ["xcodebuild", "-list", "-json", "-project", str(config.project_path)],
        config.repo_root,
        runner
    )
    if list_result.returncode != 0:
        return block_result(
            result,
            contract="xcode-project",
            reason="xcodebuild could not list the project; runnable app contract is unknown."
        )

    project_list = parse_json_output(list_result.stdout)
    if project_list is None:
        return block_result(
            result,
            contract="xcode-project",
            reason="xcodebuild -list did not return valid JSON."
        )

    schemes = project_list.get("project", {}).get("schemes", [])
    targets = project_list.get("project", {}).get("targets", [])
    result["xcode"]["available_schemes"] = schemes
    result["xcode"]["available_targets"] = targets
    if config.scheme not in schemes:
        return block_result(
            result,
            contract="xcode-scheme",
            reason=f"Scheme {config.scheme!r} is not listed by the Xcode project."
        )

    settings_result = run_step(
        result,
        "check-runnable-app-target",
        [
            "xcodebuild",
            "-showBuildSettings",
            "-json",
            "-project",
            str(config.project_path),
            "-scheme",
            config.scheme,
            "-configuration",
            config.configuration,
            "-destination",
            config.destination,
            "-derivedDataPath",
            str(config.derived_data_path)
        ],
        config.repo_root,
        runner
    )
    if settings_result.returncode != 0:
        return block_result(
            result,
            contract="xcode-build-settings",
            reason="xcodebuild could not show build settings for the selected scheme."
        )

    settings = parse_json_output(settings_result.stdout)
    app_settings = find_runnable_app_settings(settings)
    if app_settings is None:
        return block_result(
            result,
            contract="runnable-app-target",
            reason=(
                "The selected scheme did not expose a target with "
                "PRODUCT_TYPE=com.apple.product-type.application and WRAPPER_EXTENSION=app."
            )
        )

    build_settings = app_settings["buildSettings"]
    app_path = Path(build_settings.get("TARGET_BUILD_DIR", "")) / build_settings.get("FULL_PRODUCT_NAME", "")
    bundle_id = build_settings.get("PRODUCT_BUNDLE_IDENTIFIER", "")
    if not bundle_id:
        return block_result(
            result,
            contract="bundle-identifier",
            reason="Runnable app target does not expose PRODUCT_BUNDLE_IDENTIFIER."
        )
    if str(app_path) in {"", "."}:
        return block_result(
            result,
            contract="app-bundle-path",
            reason="Runnable app target does not expose TARGET_BUILD_DIR and FULL_PRODUCT_NAME."
        )

    result["xcode"].update(
        {
            "target": app_settings.get("target", ""),
            "bundle_id": bundle_id,
            "marketing_version": build_settings.get("MARKETING_VERSION", ""),
            "build_number": build_settings.get("CURRENT_PROJECT_VERSION", ""),
            "app_path": str(app_path)
        }
    )
    return {
        "target": app_settings.get("target", ""),
        "bundle_id": bundle_id,
        "app_path": str(app_path)
    }


def resolve_simulator(
    config: SmokeConfig,
    result: dict[str, Any],
    runner: CommandRunner
) -> Optional[dict[str, str]]:
    destination = parse_destination(config.destination)
    result["simulator"]["destination"] = config.destination

    simctl_result = run_step(
        result,
        "list-simulators",
        ["xcrun", "simctl", "list", "devices", "available", "-j"],
        config.repo_root,
        runner
    )
    if simctl_result.returncode != 0:
        return block_result(
            result,
            contract="simulator-list",
            reason="simctl could not list available simulators."
        )

    simctl_devices = parse_json_output(simctl_result.stdout)
    if simctl_devices is None:
        return block_result(
            result,
            contract="simulator-list",
            reason="simctl device list did not return valid JSON."
        )

    simulator = find_simulator(destination, simctl_devices)
    if simulator is None:
        return block_result(
            result,
            contract="simulator-destination",
            reason=f"No available simulator matched destination {config.destination!r}."
        )

    result["simulator"].update(simulator)
    if simulator.get("state") != "Booted":
        boot_result = run_step(
            result,
            "boot-simulator",
            ["xcrun", "simctl", "boot", simulator["udid"]],
            config.repo_root,
            runner
        )
        if boot_result.returncode != 0 and "current state: Booted" not in combined_output(boot_result):
            return block_result(
                result,
                contract="simulator-boot",
                reason=f"Simulator {simulator['udid']} could not be booted."
            )

        bootstatus_result = run_step(
            result,
            "wait-for-simulator-boot",
            ["xcrun", "simctl", "bootstatus", simulator["udid"], "-b"],
            config.repo_root,
            runner
        )
        if bootstatus_result.returncode != 0:
            return block_result(
                result,
                contract="simulator-boot",
                reason=f"Simulator {simulator['udid']} did not report a completed boot."
            )
        simulator["state"] = "Booted"
        result["simulator"]["state"] = "Booted"

    return simulator


def find_runnable_app_settings(settings: Any) -> Optional[dict[str, Any]]:
    if isinstance(settings, dict):
        records = settings.get("buildSettings", [])
        if isinstance(records, dict):
            records = [settings]
    elif isinstance(settings, list):
        records = settings
    else:
        return None

    for record in records:
        if not isinstance(record, dict):
            continue
        build_settings = record.get("buildSettings")
        if not isinstance(build_settings, dict):
            continue
        if build_settings.get("PRODUCT_TYPE") != "com.apple.product-type.application":
            continue
        if build_settings.get("WRAPPER_EXTENSION") != "app":
            continue
        return record
    return None


def parse_destination(destination: str) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw_part in destination.split(","):
        part = raw_part.strip()
        if not part or "=" not in part:
            continue
        key, value = part.split("=", 1)
        values[key.strip().lower()] = value.strip()
    return values


def find_simulator(destination: dict[str, str], simctl_devices: dict[str, Any]) -> Optional[dict[str, str]]:
    requested_id = destination.get("id")
    requested_name = destination.get("name")
    requested_os = destination.get("os")
    devices_by_runtime = simctl_devices.get("devices", {})
    if not isinstance(devices_by_runtime, dict):
        return None

    for runtime, devices in devices_by_runtime.items():
        if not isinstance(devices, list):
            continue
        for device in devices:
            if not isinstance(device, dict):
                continue
            if not device.get("isAvailable", False):
                continue
            if requested_id and device.get("udid") != requested_id:
                continue
            if requested_name and device.get("name") != requested_name:
                continue
            if requested_os and not runtime_matches(runtime, requested_os):
                continue
            return {
                "udid": str(device.get("udid", "")),
                "name": str(device.get("name", "")),
                "runtime": str(runtime),
                "state": str(device.get("state", ""))
            }
    return None


def runtime_matches(runtime_identifier: str, requested_os: str) -> bool:
    normalized_runtime = runtime_identifier.lower().replace("-", ".")
    normalized_requested = requested_os.lower()
    if normalized_requested in normalized_runtime:
        return True
    requested_parts = normalized_requested.split(".")
    if len(requested_parts) >= 2:
        major_minor = ".".join(requested_parts[:2])
        return major_minor in normalized_runtime
    return normalized_requested in normalized_runtime


def base_result(config: SmokeConfig) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "status": "blocked",
        "proof_level": None,
        "blocked_before": RUNNING_APP_PROOF_LEVEL,
        "blocked_contract": None,
        "failed_stage": None,
        "reason": "",
        "timestamp": config.timestamp,
        "repo": git_metadata(config.repo_root),
        "xcode": {
            "project": str(config.project_path),
            "scheme": config.scheme,
            "configuration": config.configuration,
            "derived_data_path": str(config.derived_data_path)
        },
        "simulator": {
            "destination": config.destination
        },
        "locale": {
            "requested_locale": config.locale,
            "apple_locale": config.apple_locale,
            "launch_arguments": locale_launch_arguments(config)
        },
        "artifacts": {},
        "steps": []
    }


def block_result(result: dict[str, Any], contract: str, reason: str) -> None:
    result["status"] = "blocked"
    result["proof_level"] = None
    result["blocked_before"] = RUNNING_APP_PROOF_LEVEL
    result["blocked_contract"] = contract
    result["reason"] = reason
    return None


def fail_result(
    result: dict[str, Any],
    stage: str,
    reason: str,
    proof_level: Optional[str]
) -> dict[str, Any]:
    result["status"] = "failed"
    result["proof_level"] = proof_level
    result["blocked_before"] = RUNNING_APP_PROOF_LEVEL
    result["failed_stage"] = stage
    result["reason"] = reason
    return result


def run_step(
    result: dict[str, Any],
    name: str,
    argv: list[str],
    cwd: Path,
    runner: CommandRunner
) -> CommandResult:
    command_result = runner(argv, cwd)
    result["steps"].append(
        {
            "name": name,
            "command": argv,
            "exit_code": command_result.returncode,
            "stdout_tail": tail(command_result.stdout),
            "stderr_tail": tail(command_result.stderr)
        }
    )
    return command_result


def default_runner(argv: list[str], cwd: Path) -> CommandResult:
    try:
        completed = subprocess.run(
            argv,
            cwd=cwd,
            text=True,
            capture_output=True,
            check=False
        )
        return CommandResult(
            argv=argv,
            returncode=completed.returncode,
            stdout=completed.stdout,
            stderr=completed.stderr
        )
    except FileNotFoundError as error:
        return CommandResult(argv=argv, returncode=127, stderr=str(error))


def parse_json_output(stdout: str) -> Optional[Any]:
    try:
        return json.loads(stdout)
    except json.JSONDecodeError:
        return None


def tail(value: str, max_chars: int = 3000) -> str:
    if len(value) <= max_chars:
        return value
    return value[-max_chars:]


def combined_output(result: CommandResult) -> str:
    return f"{result.stdout}\n{result.stderr}"


def locale_launch_arguments(config: SmokeConfig) -> list[str]:
    if not config.locale:
        return []
    apple_locale = config.apple_locale or config.locale
    return ["-AppleLanguages", f"({config.locale})", "-AppleLocale", apple_locale]


def screenshot_filename(config: SmokeConfig) -> str:
    if not config.locale:
        return "owlory-running-app-smoke.png"
    safe_locale = "".join(
        character if character.isalnum() or character in {"-", "_"} else "_"
        for character in config.locale
    )
    return f"owlory-running-app-smoke-{safe_locale}.png"


def check_localization_resources(app_path: Path, locale: str) -> Optional[dict[str, Any]]:
    locale_dir = app_path / f"{locale}.lproj"
    required_files = [locale_dir / "Localizable.strings"]
    if (app_path / "en.lproj" / "Localizable.stringsdict").exists():
        required_files.append(locale_dir / "Localizable.stringsdict")

    if not locale_dir.exists() or any(not resource.exists() for resource in required_files):
        return None

    return {
        "locale": locale,
        "resource_dir": str(locale_dir),
        "files": [
            {
                "name": resource.name,
                "path": str(resource),
                "bytes": resource.stat().st_size
            }
            for resource in required_files
        ]
    }


def timestamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def git_metadata(repo_root: Path) -> dict[str, str]:
    return {
        "commit": optional_git(repo_root, ["rev-parse", "HEAD"]),
        "short_commit": optional_git(repo_root, ["rev-parse", "--short=12", "HEAD"]),
        "branch": optional_git(repo_root, ["branch", "--show-current"]),
        "describe": optional_git(repo_root, ["describe", "--tags", "--always", "--dirty"]),
        "dirty": "yes" if optional_git(repo_root, ["status", "--porcelain"]) else "no"
    }


def optional_git(repo_root: Path, args: list[str]) -> str:
    try:
        completed = subprocess.run(
            ["git", *args],
            cwd=repo_root,
            text=True,
            capture_output=True,
            check=False
        )
    except FileNotFoundError:
        return ""
    if completed.returncode != 0:
        return ""
    return completed.stdout.strip()


if __name__ == "__main__":
    sys.exit(main())
