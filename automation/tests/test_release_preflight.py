from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
REAL_PREFLIGHT = REPO_ROOT / "Tools" / "release-preflight.sh"
REAL_VERIFIER = REPO_ROOT / "Tools" / "verify-build-provenance.sh"
PROJECT_FILE_REL = Path("owlory_xcode/Owlory.xcodeproj/project.pbxproj")


def _minimal_pbxproj(build_number: str, marketing_version: str = "1.0.0") -> str:
    return (
        "// Minimal fake pbxproj for release-preflight tests.\n"
        "objects = {\n"
        f"\tCURRENT_PROJECT_VERSION = {build_number};\n"
        f"\tMARKETING_VERSION = {marketing_version};\n"
        "};\n"
    )


class ReleasePreflightTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = Path(tempfile.mkdtemp(prefix="release-preflight-"))
        self.addCleanup(shutil.rmtree, self.tmpdir, ignore_errors=True)

        self.repo = self.tmpdir / "repo"
        self.remote = self.tmpdir / "origin.git"
        self.repo.mkdir()

        tools_dir = self.repo / "Tools"
        tools_dir.mkdir(parents=True)
        self.preflight = tools_dir / "release-preflight.sh"
        self.verifier = tools_dir / "verify-build-provenance.sh"
        shutil.copy2(REAL_PREFLIGHT, self.preflight)
        shutil.copy2(REAL_VERIFIER, self.verifier)
        os.chmod(self.preflight, 0o755)
        os.chmod(self.verifier, 0o755)

        (self.repo / "Makefile").write_text(
            "build-provenance:\n\t./Tools/verify-build-provenance.sh\n",
            encoding="utf-8",
        )

        self.pbxproj = self.repo / PROJECT_FILE_REL
        self.pbxproj.parent.mkdir(parents=True)

        self._run_git("init", "-q", "-b", "main")
        self._run_git("config", "user.email", "test@example.com")
        self._run_git("config", "user.name", "Test")
        self._run_git("config", "commit.gpgsign", "false")
        subprocess.run(["git", "init", "--bare", "-q", str(self.remote)], check=True)

    def _run_git(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", *args],
            cwd=self.repo,
            check=True,
            capture_output=True,
            text=True,
        )

    def _write_pbxproj(self, build_number: str) -> None:
        self.pbxproj.write_text(_minimal_pbxproj(build_number), encoding="utf-8")

    def _commit(self, message: str) -> None:
        self._run_git("add", ".")
        self._run_git("commit", "-q", "-m", message)

    def _seed_clean_mirrored_repo(self, build_number: str = "20260513202827") -> None:
        self._write_pbxproj(build_number)
        self._commit("Seed release metadata")
        self._run_git("remote", "add", "origin", str(self.remote))
        self._run_git("push", "-q", "-u", "origin", "main")

    def _run_preflight(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(self.preflight)],
            cwd=self.repo,
            capture_output=True,
            text=True,
        )

    def test_passes_on_clean_mirrored_committed_build_number(self) -> None:
        self._seed_clean_mirrored_repo()

        result = self._run_preflight()

        self.assertEqual(
            0,
            result.returncode,
            msg=f"expected release preflight to pass; stdout={result.stdout!r} stderr={result.stderr!r}",
        )
        self.assertIn("Working tree: clean", result.stdout)
        self.assertIn("Git mirror: 0 0", result.stdout)
        self.assertIn("Committed marketing version: matches HEAD", result.stdout)
        self.assertIn("Committed build number: matches HEAD", result.stdout)
        self.assertIn("Release preflight passed.", result.stdout)

    def test_fails_on_dirty_worktree(self) -> None:
        self._seed_clean_mirrored_repo()
        (self.repo / "UNTRACKED.txt").write_text("dirty\n", encoding="utf-8")

        result = self._run_preflight()

        self.assertNotEqual(0, result.returncode)
        self.assertIn("requires a clean working tree before Archive", result.stderr)
        self.assertIn("UNTRACKED.txt", result.stderr)

    def test_fails_on_uncommitted_build_number_bump(self) -> None:
        self._seed_clean_mirrored_repo("20260417081904")
        self._write_pbxproj("20260513202827")

        result = self._run_preflight()

        self.assertNotEqual(0, result.returncode)
        self.assertIn("requires a clean working tree before Archive", result.stderr)
        self.assertIn("Commit the intended changes", result.stderr)
        self.assertIn(str(PROJECT_FILE_REL), result.stderr)

    def test_fails_when_branch_is_not_mirrored_with_upstream(self) -> None:
        self._seed_clean_mirrored_repo()
        (self.repo / "README.md").write_text("local only\n", encoding="utf-8")
        self._commit("Local-only release note")

        result = self._run_preflight()

        self.assertNotEqual(0, result.returncode)
        self.assertIn("requires HEAD to be mirrored with upstream", result.stderr)
        self.assertIn("Push local commits", result.stderr)
        self.assertIn("Git mirror: 1 0", result.stdout)


if __name__ == "__main__":
    unittest.main()
