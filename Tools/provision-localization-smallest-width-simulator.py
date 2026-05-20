#!/usr/bin/env python3
"""Provision the deterministic iPhone SE simulator used by localization UI tests."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass
from typing import Any


TARGET_NAME = "iPhone SE"
PREFERRED_DEVICE_TYPES = [
    (
        "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation",
        "iPhone SE (3rd generation)",
    ),
    (
        "com.apple.CoreSimulator.SimDeviceType.iPhone-SE--2nd-generation-",
        "iPhone SE (2nd generation)",
    ),
    (
        "com.apple.CoreSimulator.SimDeviceType.iPhone-SE",
        "iPhone SE (1st generation)",
    ),
]


@dataclass(frozen=True)
class SimulatorChoice:
    runtime_identifier: str
    runtime_name: str
    runtime_version: str
    device_type_identifier: str
    device_type_name: str


@dataclass(frozen=True)
class ExistingDevice:
    udid: str
    name: str
    state: str
    device_type_identifier: str


class ProvisioningError(RuntimeError):
    """Raised when CoreSimulator cannot satisfy the provisioning contract."""


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            command,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    except FileNotFoundError as error:
        raise ProvisioningError(f"Command not found: {command[0]}") from error


def simctl_json(args: list[str]) -> dict[str, Any]:
    result = run(["xcrun", "simctl", "list", "-j", *args])
    if result.returncode != 0:
        raise ProvisioningError(result.stderr.strip() or result.stdout.strip())
    data = json.loads(result.stdout)
    if not isinstance(data, dict):
        raise ProvisioningError("simctl returned unexpected JSON.")
    return data


def version_key(version: str) -> tuple[int, ...]:
    pieces: list[int] = []
    for piece in version.split("."):
        try:
            pieces.append(int(piece))
        except ValueError:
            pieces.append(0)
    return tuple(pieces)


def choose_supported_simulator() -> SimulatorChoice | None:
    runtimes = simctl_json(["runtimes"]).get("runtimes", [])
    if not isinstance(runtimes, list):
        return None

    choices: list[tuple[tuple[int, ...], int, SimulatorChoice]] = []
    for runtime in runtimes:
        if not isinstance(runtime, dict) or not runtime.get("isAvailable"):
            continue

        runtime_identifier = str(runtime.get("identifier", ""))
        runtime_name = str(runtime.get("name", ""))
        runtime_version = str(runtime.get("version", ""))
        if "SimRuntime.iOS-" not in runtime_identifier and runtime.get("platform") != "iOS":
            continue

        supported_device_types = runtime.get("supportedDeviceTypes", [])
        if not isinstance(supported_device_types, list):
            continue
        supported_by_identifier = {
            str(device_type.get("identifier", "")): str(device_type.get("name", ""))
            for device_type in supported_device_types
            if isinstance(device_type, dict)
        }

        for rank, (device_type_identifier, fallback_name) in enumerate(PREFERRED_DEVICE_TYPES):
            if device_type_identifier not in supported_by_identifier:
                continue
            choice = SimulatorChoice(
                runtime_identifier=runtime_identifier,
                runtime_name=runtime_name or f"iOS {runtime_version}",
                runtime_version=runtime_version,
                device_type_identifier=device_type_identifier,
                device_type_name=supported_by_identifier[device_type_identifier] or fallback_name,
            )
            choices.append((version_key(runtime_version), len(PREFERRED_DEVICE_TYPES) - rank, choice))
            break

    if not choices:
        return None
    choices.sort(key=lambda item: (item[0], item[1]), reverse=True)
    return choices[0][2]


def find_existing_device(choice: SimulatorChoice, target_name: str) -> ExistingDevice | None:
    devices_by_runtime = simctl_json(["devices", "available"]).get("devices", {})
    if not isinstance(devices_by_runtime, dict):
        return None
    devices = devices_by_runtime.get(choice.runtime_identifier, [])
    if not isinstance(devices, list):
        return None

    preferred_identifiers = {identifier for identifier, _ in PREFERRED_DEVICE_TYPES}
    for device in devices:
        if not isinstance(device, dict):
            continue
        if device.get("name") != target_name or not device.get("isAvailable", False):
            continue
        device_type_identifier = str(device.get("deviceTypeIdentifier", ""))
        if device_type_identifier not in preferred_identifiers:
            continue
        return ExistingDevice(
            udid=str(device.get("udid", "")),
            name=str(device.get("name", "")),
            state=str(device.get("state", "")),
            device_type_identifier=device_type_identifier,
        )
    return None


def create_device(choice: SimulatorChoice, target_name: str) -> str:
    result = run([
        "xcrun",
        "simctl",
        "create",
        target_name,
        choice.device_type_identifier,
        choice.runtime_identifier,
    ])
    if result.returncode != 0:
        raise ProvisioningError(result.stderr.strip() or result.stdout.strip())
    udid = result.stdout.strip()
    if not udid:
        raise ProvisioningError("simctl create did not return a simulator UDID.")
    return udid


def destination(choice: SimulatorChoice, target_name: str) -> str:
    return f"platform=iOS Simulator,name={target_name},OS={choice.runtime_version}"


def print_choice(choice: SimulatorChoice, target_name: str) -> None:
    print(f"selected runtime: {choice.runtime_name} ({choice.runtime_identifier})")
    print(f"selected device type: {choice.device_type_name} ({choice.device_type_identifier})")
    print(f"xcodebuild destination: {destination(choice, target_name)}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Provision or check the iPhone SE simulator used by Owlory localization smallest-width tests."
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Only verify that the simulator already exists; do not create it.",
    )
    parser.add_argument(
        "--name",
        default=TARGET_NAME,
        help=f"Simulator name to check or create. Defaults to {TARGET_NAME!r}.",
    )
    args = parser.parse_args()

    try:
        choice = choose_supported_simulator()
        if choice is None:
            print(
                "No available iOS runtime supports an iPhone SE simulator device type.",
                file=sys.stderr,
            )
            return 3

        existing = find_existing_device(choice, args.name)
        if existing is not None:
            print(f"simulator already provisioned: {existing.name} ({existing.udid}) [{existing.state}]")
            print_choice(choice, args.name)
            return 0

        if args.check:
            print(
                f"simulator named {args.name!r} is missing for {choice.runtime_name}. "
                "Run `make provision-localization-smallest-width-simulator`.",
                file=sys.stderr,
            )
            print_choice(choice, args.name)
            return 1

        udid = create_device(choice, args.name)
        print(f"created simulator: {args.name} ({udid})")
        print_choice(choice, args.name)
        return 0
    except (ProvisioningError, json.JSONDecodeError) as error:
        print(f"simulator provisioning failed: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
