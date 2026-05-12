from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
REAL_VERIFIER = REPO_ROOT / "Tools" / "verify-build-provenance.sh"
PROJECT_FILE_REL = Path("owlory_xcode/Owlory.xcodeproj/project.pbxproj")


def _minimal_pbxproj(build_number: str, marketing_version: str = "1.0.0") -> str:
    return (
        "// Minimal fake pbxproj for verify-build-provenance.sh tests.\n"
        "objects = {\n"
        f"\tCURRENT_PROJECT_VERSION = {build_number};\n"
        f"\tMARKETING_VERSION = {marketing_version};\n"
        "};\n"
    )


class VerifyBuildProvenanceCommittedBuildGateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = Path(tempfile.mkdtemp(prefix="verify-prov-gate-"))
        self.addCleanup(shutil.rmtree, self.tmpdir, ignore_errors=True)

        tools_dir = self.tmpdir / "Tools"
        tools_dir.mkdir(parents=True)
        self.verifier = tools_dir / "verify-build-provenance.sh"
        shutil.copy2(REAL_VERIFIER, self.verifier)
        os.chmod(self.verifier, 0o755)

        self.pbxproj = self.tmpdir / PROJECT_FILE_REL
        self.pbxproj.parent.mkdir(parents=True)

        self._run_git("init", "-q", "-b", "main")
        self._run_git("config", "user.email", "test@example.com")
        self._run_git("config", "user.name", "Test")
        self._run_git("config", "commit.gpgsign", "false")

    def _run_git(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", *args],
            cwd=self.tmpdir,
            check=True,
            capture_output=True,
            text=True,
        )

    def _write_pbxproj(self, build_number: str) -> None:
        self.pbxproj.write_text(_minimal_pbxproj(build_number))

    def _commit_pbxproj(self, build_number: str, message: str) -> None:
        self._write_pbxproj(build_number)
        self._run_git(
            "add",
            str(PROJECT_FILE_REL),
            "Tools/verify-build-provenance.sh",
        )
        self._run_git("commit", "-q", "-m", message)

    def _run_verifier(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(self.verifier), *args],
            cwd=self.tmpdir,
            capture_output=True,
            text=True,
        )

    def test_committed_build_matches_on_disk_passes_under_require_clean(self) -> None:
        self._commit_pbxproj("20260417081904", "Seed pbxproj")

        result = self._run_verifier("--require-clean")

        self.assertEqual(
            0,
            result.returncode,
            msg=f"expected exit 0; stdout={result.stdout!r} stderr={result.stderr!r}",
        )
        self.assertIn("Committed build number: matches HEAD", result.stdout)

    def test_uncommitted_build_bump_fails_under_require_clean(self) -> None:
        self._commit_pbxproj("20260417081904", "Seed pbxproj")
        self._write_pbxproj("20260417081911")

        result = self._run_verifier("--require-clean")

        self.assertNotEqual(
            0,
            result.returncode,
            msg=f"expected non-zero exit; stdout={result.stdout!r} stderr={result.stderr!r}",
        )
        self.assertIn(
            "is not committed at HEAD",
            result.stderr,
            msg=f"expected committed-build error message; stderr={result.stderr!r}",
        )
        self.assertIn(
            "commit the build-number bump before re-running the verifier",
            result.stderr,
            msg=f"expected remediation guidance; stderr={result.stderr!r}",
        )

    def test_uncommitted_build_bump_is_advisory_without_require_clean(self) -> None:
        self._commit_pbxproj("20260417081904", "Seed pbxproj")
        self._write_pbxproj("20260417081911")

        result = self._run_verifier()

        self.assertEqual(
            0,
            result.returncode,
            msg=f"expected exit 0 in informational mode; stderr={result.stderr!r}",
        )
        self.assertIn(
            "Committed build number: differs from HEAD (HEAD has 20260417081904)",
            result.stdout,
        )


if __name__ == "__main__":
    unittest.main()
