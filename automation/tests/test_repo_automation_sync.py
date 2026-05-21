from __future__ import annotations

import json
import os
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
SYNC_TOOL = REPO_ROOT / "Tools" / "repo-automation-sync.sh"


class RepoAutomationSyncTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = Path(tempfile.mkdtemp(prefix="repo-automation-sync-"))
        self.addCleanup(shutil.rmtree, self.tmpdir, ignore_errors=True)
        self.source = self.tmpdir / "source"
        self.target = self.tmpdir / "target"
        self.source.mkdir()
        self.target.mkdir()
        self.manifest = self.source / "manifest.json"

    def write_source(self, relative: str, contents: str, mode: int = 0o644) -> Path:
        path = self.source / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents, encoding="utf-8")
        os.chmod(path, mode)
        return path

    def write_target(self, relative: str, contents: str, mode: int = 0o644) -> Path:
        path = self.target / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents, encoding="utf-8")
        os.chmod(path, mode)
        return path

    def write_manifest(self, entries: list[dict[str, Any]]) -> None:
        self.manifest.write_text(
            json.dumps(
                {
                    "version": 1,
                    "default_target": str(self.target),
                    "entries": entries,
                },
                indent=2,
            ),
            encoding="utf-8",
        )

    def entry(
        self,
        source: str,
        destination: str,
        kind: str = "file",
        preserve_executable: bool = False,
        delete_stale: bool = False,
        template: bool = False,
        allow_owlory_specific: bool = False,
    ) -> dict[str, Any]:
        raw: dict[str, Any] = {
            "source": source,
            "destination": destination,
            "kind": kind,
            "preserve_executable": preserve_executable,
            "delete_stale": delete_stale,
            "template": template,
        }
        if allow_owlory_specific:
            raw["allow_owlory_specific"] = True
        return raw

    def run_tool(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                str(SYNC_TOOL),
                *args,
                "--source",
                str(self.source),
                "--manifest",
                str(self.manifest),
                "--target",
                str(self.target),
            ],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )

    def test_sync_copies_entries_and_preserves_executable_mode(self) -> None:
        self.write_source("docs/readme.md", "hello\n")
        self.write_source("Tools/run.sh", "#!/bin/sh\nexit 0\n", mode=0o755)
        self.write_manifest(
            [
                self.entry("docs/readme.md", "docs/readme.md"),
                self.entry(
                    "Tools/run.sh",
                    "Tools/run.sh",
                    preserve_executable=True,
                ),
            ]
        )

        result = self.run_tool("--sync")

        self.assertEqual(0, result.returncode, msg=result.stderr)
        self.assertEqual("hello\n", (self.target / "docs/readme.md").read_text(encoding="utf-8"))
        self.assertTrue(
            stat.S_IMODE((self.target / "Tools/run.sh").stat().st_mode) & 0o111
        )

        check_result = self.run_tool("--check")
        self.assertEqual(0, check_result.returncode, msg=check_result.stdout + check_result.stderr)
        self.assertIn("result: target is current", check_result.stdout)

        second_sync = self.run_tool("--sync")
        self.assertEqual(0, second_sync.returncode, msg=second_sync.stderr)
        self.assertIn("result: already current", second_sync.stdout)

    def test_check_reports_drift_without_mutating_target(self) -> None:
        self.write_source("a.txt", "source\n")
        self.write_target("mirror/a.txt", "target\n")
        self.write_manifest([self.entry("a.txt", "mirror/a.txt")])

        result = self.run_tool("--check")

        self.assertNotEqual(0, result.returncode)
        self.assertIn("changed: mirror/a.txt", result.stdout)
        self.assertEqual("target\n", (self.target / "mirror/a.txt").read_text(encoding="utf-8"))

    def test_sync_removes_stale_files_only_under_delete_stale_entries(self) -> None:
        self.write_source("owned/keep.txt", "keep\n")
        self.write_source("not-owned/keep.txt", "keep\n")
        self.write_target("mirror/owned/stale.txt", "stale\n")
        self.write_target("mirror/not-owned/stale.txt", "stale\n")
        self.write_target("outside.txt", "outside\n")
        self.write_manifest(
            [
                self.entry(
                    "owned",
                    "mirror/owned",
                    kind="directory",
                    delete_stale=True,
                ),
                self.entry(
                    "not-owned",
                    "mirror/not-owned",
                    kind="directory",
                    delete_stale=False,
                ),
            ]
        )

        result = self.run_tool("--sync")

        self.assertEqual(0, result.returncode, msg=result.stderr)
        self.assertFalse((self.target / "mirror/owned/stale.txt").exists())
        self.assertTrue((self.target / "mirror/not-owned/stale.txt").exists())
        self.assertTrue((self.target / "outside.txt").exists())

    def test_forbidden_owlory_state_requires_explicit_manifest_approval(self) -> None:
        self.write_source("automation/queue/slices.json", "{}\n")
        self.write_manifest(
            [
                self.entry(
                    "automation/queue/slices.json",
                    "automation/queue/slices.json",
                )
            ]
        )

        rejected = self.run_tool("--sync")

        self.assertNotEqual(0, rejected.returncode)
        self.assertIn("forbidden Owlory-specific source", rejected.stderr)
        self.assertFalse((self.target / "automation/queue/slices.json").exists())

        self.write_manifest(
            [
                self.entry(
                    "automation/queue/slices.json",
                    "automation/queue/slices.json",
                    allow_owlory_specific=True,
                )
            ]
        )

        accepted = self.run_tool("--sync")

        self.assertEqual(0, accepted.returncode, msg=accepted.stderr)
        self.assertEqual(
            "{}\n",
            (self.target / "automation/queue/slices.json").read_text(encoding="utf-8"),
        )

    def test_check_reports_missing_target_without_creating_it(self) -> None:
        self.write_source("a.txt", "source\n")
        self.write_manifest([self.entry("a.txt", "a.txt")])
        shutil.rmtree(self.target)

        result = self.run_tool("--check")

        self.assertNotEqual(0, result.returncode)
        self.assertIn("missing target:", result.stdout)
        self.assertFalse(self.target.exists())


if __name__ == "__main__":
    unittest.main()
