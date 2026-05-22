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

    def init_target_git_repo(self) -> None:
        init = subprocess.run(
            ["git", "init", "-b", "main"],
            cwd=self.target,
            capture_output=True,
            text=True,
        )
        self.assertEqual(0, init.returncode, msg=init.stderr)

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

    def test_auto_update_fails_when_target_is_missing(self) -> None:
        self.write_source("a.txt", "source\n")
        self.write_manifest([self.entry("a.txt", "a.txt")])
        shutil.rmtree(self.target)

        result = self.run_tool("--auto-update")

        self.assertNotEqual(0, result.returncode)
        self.assertIn("auto-update refused", result.stdout)
        self.assertFalse(self.target.exists())

    def test_auto_update_fails_when_target_is_not_git_repo(self) -> None:
        self.write_source("a.txt", "source\n")
        self.write_manifest([self.entry("a.txt", "a.txt")])

        result = self.run_tool("--auto-update")

        self.assertNotEqual(0, result.returncode)
        self.assertIn("auto-update target is not a Git repository", result.stderr)
        self.assertFalse((self.target / "a.txt").exists())

    def test_auto_update_fails_when_target_has_local_dirt(self) -> None:
        self.init_target_git_repo()
        self.write_source("a.txt", "source\n")
        self.write_target("a.txt", "local edit\n")
        self.write_manifest([self.entry("a.txt", "a.txt")])

        result = self.run_tool("--auto-update")

        self.assertNotEqual(0, result.returncode)
        self.assertIn("refusing auto-update because target has local dirt", result.stderr)
        self.assertEqual("local edit\n", (self.target / "a.txt").read_text(encoding="utf-8"))

    def test_auto_update_syncs_clean_git_target_and_verifies_current(self) -> None:
        self.init_target_git_repo()
        self.write_source("a.txt", "source\n")
        self.write_manifest([self.entry("a.txt", "a.txt")])

        result = self.run_tool("--auto-update")

        self.assertEqual(0, result.returncode, msg=result.stderr)
        self.assertEqual("source\n", (self.target / "a.txt").read_text(encoding="utf-8"))
        self.assertIn("result: synced 1 change(s)", result.stdout)
        self.assertIn("result: target is current", result.stdout)


class RepoAutomationConsumerAdoptionSmokeTests(unittest.TestCase):
    REUSABLE_PRESENT_PATHS = (
        "Tools/repo-automation-sync.sh",
        "automation/README.md",
        "automation/context/build_context.py",
        "automation/reusable-manifest.json",
        "automation/schemas/handoff.schema.json",
        "automation/schemas/slice.schema.json",
        "automation/supervisor/policy.py",
        "automation/supervisor/run_next.py",
        "automation/supervisor/run_agent.sh",
        "automation/tests/test_harness.py",
        "automation/prompts/base.md",
        "automation/prompts/slice.md",
        "automation/examples/example-slices.json",
        "automation/examples/example-handoff.json",
        "docs/workflows/repo-automation.md",
        "pyrightconfig.json",
    )

    OWLORY_SPECIFIC_ABSENT_PATHS = (
        "automation/queue/slices.json",
        "automation/handoffs",
        "automation/proofs",
        "automation/smoke",
        "SecondBrain",
        "owlory_xcode",
        "localization",
        "docs/product",
        "docs/runtime",
        "Tools/bump-version.sh",
        "Tools/set-build-number.sh",
        "Tools/verify-build-provenance.sh",
        ".githooks/pre-push",
    )

    def setUp(self) -> None:
        self.tmpdir = Path(tempfile.mkdtemp(prefix="repo-automation-consumer-"))
        self.addCleanup(shutil.rmtree, self.tmpdir, ignore_errors=True)
        self.consumer = self.tmpdir / "consumer-repo"
        self.consumer.mkdir()

    def bootstrap_consumer(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                str(SYNC_TOOL),
                "--sync",
                "--target",
                str(self.consumer),
            ],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )

    def init_consumer_git(self, commit_bootstrap: bool = True) -> None:
        init = subprocess.run(
            ["git", "init", "-b", "main"],
            cwd=self.consumer,
            capture_output=True,
            text=True,
        )
        self.assertEqual(0, init.returncode, msg=init.stderr)
        for key, value in (
            ("user.email", "smoke@example.test"),
            ("user.name", "consumer-smoke"),
            ("commit.gpgsign", "false"),
        ):
            subprocess.run(
                ["git", "config", key, value],
                cwd=self.consumer,
                check=True,
                capture_output=True,
                text=True,
            )
        if commit_bootstrap:
            subprocess.run(
                ["git", "add", "-A"],
                cwd=self.consumer,
                check=True,
                capture_output=True,
                text=True,
            )
            subprocess.run(
                ["git", "commit", "-m", "Bootstrap reusable automation"],
                cwd=self.consumer,
                check=True,
                capture_output=True,
                text=True,
            )

    def seed_example_queue(self) -> None:
        queue_dir = self.consumer / "automation/queue"
        queue_dir.mkdir(parents=True, exist_ok=True)
        example = self.consumer / "automation/examples/example-slices.json"
        shutil.copy(example, queue_dir / "slices.json")
        (self.consumer / "automation/handoffs").mkdir(parents=True, exist_ok=True)
        gitdir = self.consumer / ".git"
        if gitdir.exists():
            subprocess.run(
                ["git", "add", "-A"],
                cwd=self.consumer,
                check=True,
                capture_output=True,
                text=True,
            )
            subprocess.run(
                ["git", "commit", "-m", "Seed consumer queue"],
                cwd=self.consumer,
                check=True,
                capture_output=True,
                text=True,
            )

    def test_consumer_bootstrap_lands_only_reusable_subset(self) -> None:
        bootstrap = self.bootstrap_consumer()
        self.assertEqual(0, bootstrap.returncode, msg=bootstrap.stderr)

        for relative in self.REUSABLE_PRESENT_PATHS:
            self.assertTrue(
                (self.consumer / relative).exists(),
                msg=f"reusable asset missing after bootstrap: {relative}",
            )

        for relative in self.OWLORY_SPECIFIC_ABSENT_PATHS:
            self.assertFalse(
                (self.consumer / relative).exists(),
                msg=f"Owlory-specific path leaked into consumer: {relative}",
            )

        run_agent = self.consumer / "automation/supervisor/run_agent.sh"
        self.assertTrue(
            stat.S_IMODE(run_agent.stat().st_mode) & 0o111,
            msg="supervisor run_agent.sh must remain executable in consumer",
        )
        sync_tool = self.consumer / "Tools/repo-automation-sync.sh"
        self.assertTrue(
            stat.S_IMODE(sync_tool.stat().st_mode) & 0o111,
            msg="repo-automation-sync.sh must remain executable in consumer",
        )

    def test_consumer_supervisor_fails_with_friendly_message_without_queue_file(self) -> None:
        self.bootstrap_consumer()
        self.init_consumer_git()

        result = subprocess.run(
            ["python3", "automation/supervisor/run_next.py", "--dry-run"],
            cwd=self.consumer,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(0, result.returncode)
        combined = result.stdout + result.stderr
        self.assertNotIn("Traceback", combined)
        self.assertIn("queue file not found", combined)
        self.assertIn("automation/queue/slices.json", combined)
        self.assertIn("example-slices.json", combined)

    def test_consumer_context_builder_fails_with_friendly_message_without_queue_file(self) -> None:
        self.bootstrap_consumer()
        self.init_consumer_git()

        result = subprocess.run(
            [
                "python3",
                "automation/context/build_context.py",
                "--slice-id",
                "any-slice",
            ],
            cwd=self.consumer,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(0, result.returncode)
        combined = result.stdout + result.stderr
        self.assertNotIn("Traceback", combined)
        self.assertIn("queue file not found", combined)
        self.assertIn("automation/queue/slices.json", combined)

    def test_consumer_supervisor_dry_run_works_with_example_queue(self) -> None:
        self.bootstrap_consumer()
        self.init_consumer_git()
        self.seed_example_queue()

        env = os.environ.copy()
        env["PYTHONDONTWRITEBYTECODE"] = "1"
        result = subprocess.run(
            ["python3", "automation/supervisor/run_next.py", "--dry-run"],
            cwd=self.consumer,
            capture_output=True,
            text=True,
            env=env,
        )

        self.assertEqual(0, result.returncode, msg=result.stderr)
        combined = result.stdout + result.stderr
        self.assertNotIn("Traceback", combined)
        self.assertTrue(
            "selected_slice" in combined or "no eligible queued slice" in combined,
            msg=f"unexpected dry-run output: {combined[:400]}",
        )
        self.assertIn(
            str(self.consumer),
            combined,
            msg="dry-run handoff path should resolve under the consumer repo, not Owlory",
        )

    def test_consumer_supervisor_surfaces_friendly_message_outside_git_repo(self) -> None:
        self.bootstrap_consumer()
        self.seed_example_queue()

        result = subprocess.run(
            ["python3", "automation/supervisor/run_next.py", "--dry-run"],
            cwd=self.consumer,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(0, result.returncode)
        combined = result.stdout + result.stderr
        self.assertNotIn("Traceback", combined)
        self.assertIn("not a Git repository", combined)
        self.assertIn("git init -b main", combined)

    def test_consumer_auto_update_round_trip_after_git_init(self) -> None:
        self.bootstrap_consumer()
        self.init_consumer_git()

        auto = subprocess.run(
            [
                str(SYNC_TOOL),
                "--auto-update",
                "--target",
                str(self.consumer),
            ],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )

        self.assertEqual(0, auto.returncode, msg=auto.stderr)
        self.assertIn("result: target is current", auto.stdout)

    def test_consumer_supervisor_fails_with_friendly_message_when_git_not_on_path(self) -> None:
        self.bootstrap_consumer()
        self.init_consumer_git()
        self.seed_example_queue()

        python_only_bin = self.tmpdir / "python-only-bin"
        python_only_bin.mkdir(exist_ok=True)
        python_exec = shutil.which("python3")
        if python_exec is None:
            self.skipTest("python3 not found on PATH; cannot construct an isolated bin")
        os.symlink(python_exec, python_only_bin / "python3")

        env = os.environ.copy()
        env["PYTHONDONTWRITEBYTECODE"] = "1"
        env["PATH"] = str(python_only_bin)

        result = subprocess.run(
            [str(python_only_bin / "python3"), "automation/supervisor/run_next.py", "--dry-run"],
            cwd=self.consumer,
            capture_output=True,
            text=True,
            env=env,
        )

        self.assertNotEqual(0, result.returncode)
        combined = result.stdout + result.stderr
        self.assertNotIn("Traceback", combined)
        self.assertIn("git executable not found on PATH", combined)

    def test_consumer_supervisor_fails_with_friendly_message_on_corrupt_git_repo(self) -> None:
        self.bootstrap_consumer()
        self.init_consumer_git()
        self.seed_example_queue()

        head_path = self.consumer / ".git/HEAD"
        head_path.write_text("garbage-not-a-valid-ref\n", encoding="utf-8")

        env = os.environ.copy()
        env["PYTHONDONTWRITEBYTECODE"] = "1"
        result = subprocess.run(
            ["python3", "automation/supervisor/run_next.py", "--dry-run"],
            cwd=self.consumer,
            capture_output=True,
            text=True,
            env=env,
        )

        self.assertNotEqual(0, result.returncode)
        combined = result.stdout + result.stderr
        self.assertNotIn("Traceback", combined)
        self.assertIn("git command failed in", combined)
        self.assertIn(str(self.consumer), combined)

    def test_consumer_supervisor_fails_with_friendly_message_on_malformed_queue_json(self) -> None:
        self.bootstrap_consumer()
        self.init_consumer_git()
        queue_dir = self.consumer / "automation/queue"
        queue_dir.mkdir(parents=True, exist_ok=True)
        (queue_dir / "slices.json").write_text("{invalid json,\n", encoding="utf-8")

        result = subprocess.run(
            ["python3", "automation/supervisor/run_next.py", "--dry-run"],
            cwd=self.consumer,
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(0, result.returncode)
        combined = result.stdout + result.stderr
        self.assertNotIn("Traceback", combined)
        self.assertIn("invalid JSON in", combined)
        self.assertIn("automation/queue/slices.json", combined)

    def test_force_templates_overwrites_consumer_override(self) -> None:
        self.bootstrap_consumer()
        self.init_consumer_git()

        sentinel = "FORCE-TEMPLATES-OVERWRITE-SENTINEL-58104"
        base_md = self.consumer / "automation/prompts/base.md"
        owlory_base_text = (REPO_ROOT / "automation/prompts/base.md").read_text(encoding="utf-8")
        base_md.write_text(
            f"# Consumer override\n\n{sentinel}\n", encoding="utf-8"
        )

        subprocess.run(
            ["git", "add", "-A"],
            cwd=self.consumer,
            check=True,
            capture_output=True,
            text=True,
        )
        subprocess.run(
            ["git", "commit", "-m", "Override base prompt"],
            cwd=self.consumer,
            check=True,
            capture_output=True,
            text=True,
        )

        baseline = subprocess.run(
            [str(SYNC_TOOL), "--sync", "--target", str(self.consumer)],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(0, baseline.returncode, msg=baseline.stderr)
        self.assertIn(
            sentinel,
            base_md.read_text(encoding="utf-8"),
            msg="default --sync should preserve the override",
        )

        forced = subprocess.run(
            [str(SYNC_TOOL), "--sync", "--force-templates", "--target", str(self.consumer)],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(0, forced.returncode, msg=forced.stderr)
        rebaseline = base_md.read_text(encoding="utf-8")
        self.assertNotIn(
            sentinel,
            rebaseline,
            msg="--force-templates must overwrite the consumer override with the source content",
        )
        self.assertEqual(
            owlory_base_text,
            rebaseline,
            msg="--force-templates must produce content identical to the Owlory source base.md",
        )

    def test_force_templates_preserves_consumer_added_files(self) -> None:
        self.bootstrap_consumer()
        self.init_consumer_git()

        added = self.consumer / "automation/prompts/consumer-only.md"
        added_text = "# Consumer-only fragment that should survive --force-templates\n"
        added.write_text(added_text, encoding="utf-8")

        subprocess.run(
            ["git", "add", "-A"],
            cwd=self.consumer,
            check=True,
            capture_output=True,
            text=True,
        )
        subprocess.run(
            ["git", "commit", "-m", "Add consumer-only prompt"],
            cwd=self.consumer,
            check=True,
            capture_output=True,
            text=True,
        )

        result = subprocess.run(
            [str(SYNC_TOOL), "--sync", "--force-templates", "--target", str(self.consumer)],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(0, result.returncode, msg=result.stderr)

        self.assertTrue(
            added.exists(),
            msg="--force-templates must NOT delete consumer-added files in template directories",
        )
        self.assertEqual(
            added_text,
            added.read_text(encoding="utf-8"),
            msg="--force-templates must preserve the content of consumer-added files",
        )

    def test_consumer_prompt_override_survives_resync(self) -> None:
        self.bootstrap_consumer()
        self.init_consumer_git()

        sentinel = "PROMPT-OVERRIDE-SURVIVES-RESYNC-SENTINEL-77231"
        base_md = self.consumer / "automation/prompts/base.md"
        base_md.write_text(f"# Consumer base prompt\n\n{sentinel}\n", encoding="utf-8")

        subprocess.run(
            ["git", "add", "-A"],
            cwd=self.consumer,
            check=True,
            capture_output=True,
            text=True,
        )
        subprocess.run(
            ["git", "commit", "-m", "Override base prompt"],
            cwd=self.consumer,
            check=True,
            capture_output=True,
            text=True,
        )

        result = subprocess.run(
            [str(SYNC_TOOL), "--sync", "--target", str(self.consumer)],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(0, result.returncode, msg=result.stderr)

        self.assertIn(
            sentinel,
            base_md.read_text(encoding="utf-8"),
            msg="customized base.md must survive --sync because the prompts entry is template-managed",
        )

    def test_consumer_added_prompt_file_survives_resync(self) -> None:
        self.bootstrap_consumer()
        self.init_consumer_git()

        added = self.consumer / "automation/prompts/consumer-custom.md"
        added_text = "# Consumer-only prompt fragment\n"
        added.write_text(added_text, encoding="utf-8")

        subprocess.run(
            ["git", "add", "-A"],
            cwd=self.consumer,
            check=True,
            capture_output=True,
            text=True,
        )
        subprocess.run(
            ["git", "commit", "-m", "Add consumer prompt"],
            cwd=self.consumer,
            check=True,
            capture_output=True,
            text=True,
        )

        result = subprocess.run(
            [str(SYNC_TOOL), "--sync", "--target", str(self.consumer)],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(0, result.returncode, msg=result.stderr)

        self.assertTrue(
            added.exists(),
            msg="consumer-added prompt file must survive --sync because the entry sets delete_stale=false",
        )
        self.assertEqual(
            added_text,
            added.read_text(encoding="utf-8"),
            msg="consumer-added prompt file must keep its content after --sync",
        )

    def test_consumer_can_override_prompt_fragments(self) -> None:
        self.bootstrap_consumer()
        self.init_consumer_git()
        self.seed_example_queue()

        slice_marker = "CONSUMER-SLICE-PROMPT-OVERRIDE-SENTINEL-91827"
        base_marker = "CONSUMER-BASE-PROMPT-OVERRIDE-SENTINEL-46352"

        (self.consumer / "automation/prompts/slice.md").write_text(
            "# Custom Slice Brief\n\nSlice: __SLICE_ID__\n\n"
            f"{slice_marker}\n",
            encoding="utf-8",
        )
        (self.consumer / "automation/prompts/base.md").write_text(
            f"# Custom Base\n\n{base_marker}\n",
            encoding="utf-8",
        )

        subprocess.run(
            ["git", "add", "-A"],
            cwd=self.consumer,
            check=True,
            capture_output=True,
            text=True,
        )
        subprocess.run(
            ["git", "commit", "-m", "Override prompt fragments"],
            cwd=self.consumer,
            check=True,
            capture_output=True,
            text=True,
        )

        probe = (
            "import json, sys\n"
            "from pathlib import Path\n"
            "sys.path.insert(0, str(Path.cwd()))\n"
            "from automation.supervisor.run_next import render_prompt\n"
            "from automation.supervisor import policy\n"
            "from automation.context.build_context import build_context_bundle\n"
            "queue_path = Path('automation/queue/slices.json')\n"
            "schema_path = Path('automation/schemas/slice.schema.json')\n"
            "queue_data = policy.load_queue(queue_path, schema_path)\n"
            "slice_record = policy.select_next_slice(queue_data)\n"
            "bundle = build_context_bundle(\n"
            "    repo_root=Path.cwd(),\n"
            "    queue_path=queue_path,\n"
            "    handoff_dir=Path('automation/handoffs'),\n"
            "    slice_id=slice_record['slice_id'],\n"
            "    max_doc_chars=200,\n"
            ")\n"
            "rendered = render_prompt(\n"
            "    Path.cwd(),\n"
            "    slice_record,\n"
            "    bundle,\n"
            "    Path('automation/handoffs/probe.json'),\n"
            ")\n"
            "print(rendered)\n"
        )

        env = os.environ.copy()
        env["PYTHONDONTWRITEBYTECODE"] = "1"
        result = subprocess.run(
            ["python3", "-c", probe],
            cwd=self.consumer,
            capture_output=True,
            text=True,
            env=env,
        )

        self.assertEqual(0, result.returncode, msg=result.stderr)
        self.assertIn(slice_marker, result.stdout)
        self.assertIn(base_marker, result.stdout)
        self.assertNotIn(
            "Owlory Supervised Slice Run",
            result.stdout,
            msg="Owlory's default base.md text should not appear when the consumer has overridden base.md",
        )


if __name__ == "__main__":
    unittest.main()
