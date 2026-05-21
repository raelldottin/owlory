from __future__ import annotations

import os
import re
import shutil
import subprocess
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
REAL_BUMP_VERSION = REPO_ROOT / "Tools" / "bump-version.sh"
REAL_SET_BUILD_NUMBER = REPO_ROOT / "Tools" / "set-build-number.sh"
PROJECT_FILE_REL = Path("owlory_xcode/Owlory.xcodeproj/project.pbxproj")


def _minimal_pbxproj(marketing_version: str, build_number: str) -> str:
    return (
        "// Minimal fake pbxproj for release script tests.\n"
        "objects = {\n"
        f"\t\tMARKETING_VERSION = {marketing_version};\n"
        f"\t\tCURRENT_PROJECT_VERSION = {build_number};\n"
        f"\t\tMARKETING_VERSION = {marketing_version};\n"
        f"\t\tCURRENT_PROJECT_VERSION = {build_number};\n"
        "};\n"
    )


def _minimal_changelog() -> str:
    return (
        "# Changelog\n"
        "\n"
        "## [Unreleased]\n"
        "\n"
        "- Pending release note.\n"
        "\n"
        "## [0.2.3] - 2026-01-01\n"
        "\n"
        "- Previous release.\n"
    )


class ReleaseVersionScriptTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = Path(tempfile.mkdtemp(prefix="release-version-scripts-"))
        self.addCleanup(shutil.rmtree, self.tmpdir, ignore_errors=True)

        tools_dir = self.tmpdir / "Tools"
        tools_dir.mkdir(parents=True)
        self.bump_version = tools_dir / "bump-version.sh"
        self.set_build_number = tools_dir / "set-build-number.sh"
        shutil.copy2(REAL_BUMP_VERSION, self.bump_version)
        shutil.copy2(REAL_SET_BUILD_NUMBER, self.set_build_number)
        os.chmod(self.bump_version, 0o755)
        os.chmod(self.set_build_number, 0o755)

        self.pbxproj = self.tmpdir / PROJECT_FILE_REL
        self.pbxproj.parent.mkdir(parents=True)
        self.changelog = self.tmpdir / "CHANGELOG.md"

    def _seed_project(
        self,
        marketing_version: str = "0.2.3",
        build_number: str = "20260101000000",
    ) -> None:
        self.pbxproj.write_text(
            _minimal_pbxproj(marketing_version, build_number),
            encoding="utf-8",
        )
        self.changelog.write_text(_minimal_changelog(), encoding="utf-8")

    def _run(
        self,
        script: Path,
        *args: str,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(script), *args],
            cwd=self.tmpdir,
            capture_output=True,
            text=True,
        )

    def _marketing_values(self) -> list[str]:
        return re.findall(
            r"MARKETING_VERSION = ([^;]+);",
            self.pbxproj.read_text(encoding="utf-8"),
        )

    def _build_values(self) -> list[str]:
        return re.findall(
            r"CURRENT_PROJECT_VERSION = ([^;]+);",
            self.pbxproj.read_text(encoding="utf-8"),
        )

    def test_bump_version_applies_major_minor_patch_policy(self) -> None:
        cases = {
            "major": "1.0.0",
            "minor": "0.3.0",
            "patch": "0.2.4",
        }

        for bump_type, expected_version in cases.items():
            with self.subTest(bump_type=bump_type):
                self._seed_project()

                result = self._run(self.bump_version, bump_type)

                self.assertEqual(
                    0,
                    result.returncode,
                    msg=f"stdout={result.stdout!r} stderr={result.stderr!r}",
                )
                self.assertEqual([expected_version, expected_version], self._marketing_values())
                build_values = self._build_values()
                self.assertEqual(2, len(build_values))
                self.assertEqual(1, len(set(build_values)))
                self.assertRegex(build_values[0], r"^\d{14}$")
                self.assertLessEqual(len(build_values[0]), 18)
                self.assertIn(
                    f"Bumping MARKETING_VERSION: 0.2.3 -> {expected_version}",
                    result.stdout,
                )
                self.assertIn(
                    f"## [{expected_version}] - {datetime.now(timezone.utc):%Y-%m-%d}",
                    self.changelog.read_text(encoding="utf-8"),
                )

    def test_bump_version_rejects_unknown_bump_type_without_mutating_files(self) -> None:
        self._seed_project()
        before_pbxproj = self.pbxproj.read_text(encoding="utf-8")
        before_changelog = self.changelog.read_text(encoding="utf-8")

        result = self._run(self.bump_version, "build")

        self.assertNotEqual(0, result.returncode)
        self.assertIn("bump type must be 'major', 'minor', or 'patch'", result.stderr)
        self.assertEqual(before_pbxproj, self.pbxproj.read_text(encoding="utf-8"))
        self.assertEqual(before_changelog, self.changelog.read_text(encoding="utf-8"))

    def test_set_build_number_updates_all_configs_without_changing_marketing_version(self) -> None:
        self._seed_project(marketing_version="0.4.0", build_number="20260101000000")

        result = self._run(self.set_build_number, "20260521080102")

        self.assertEqual(
            0,
            result.returncode,
            msg=f"stdout={result.stdout!r} stderr={result.stderr!r}",
        )
        self.assertEqual(["0.4.0", "0.4.0"], self._marketing_values())
        self.assertEqual(["20260521080102", "20260521080102"], self._build_values())
        self.assertIn(
            "Set CURRENT_PROJECT_VERSION to 20260521080102 for Owlory 0.4.0.",
            result.stdout,
        )

    def test_set_build_number_rejects_invalid_or_too_long_values_without_mutating_file(self) -> None:
        for value in ("2026-05-21", "1234567890123456789"):
            with self.subTest(value=value):
                self._seed_project()
                before_pbxproj = self.pbxproj.read_text(encoding="utf-8")

                result = self._run(self.set_build_number, value)

                self.assertNotEqual(0, result.returncode)
                self.assertEqual(before_pbxproj, self.pbxproj.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
