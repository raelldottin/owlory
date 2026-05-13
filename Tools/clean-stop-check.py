#!/usr/bin/env python3
"""Read-only clean-stop verifier for Owlory agents."""

from __future__ import annotations

import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OPEN_STATUSES = {"queued", "in_progress", "ready"}
PARKED_STATUSES = {"blocked", "deferred"}


@dataclass
class Failure:
    rule: str
    why: str
    fix: str


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False
    )


def load_queue() -> dict:
    sys.path.insert(0, str(ROOT))
    from automation.supervisor import policy  # pylint: disable=import-outside-toplevel

    return policy.load_queue(
        ROOT / "automation/queue/slices.json",
        ROOT / "automation/schemas/slice.schema.json"
    )


def check_git_clean(failures: list[Failure]) -> tuple[bool, str]:
    result = run(["git", "status", "--short", "--untracked-files=all"])
    if result.returncode != 0:
        failures.append(Failure(
            rule="Git cleanliness could not be checked.",
            why="A clean stop must prove whether local edits or untracked files exist.",
            fix=f"Fix Git access or run from a Git checkout, then rerun `make clean-stop`. stderr: {result.stderr.strip()}"
        ))
        return False, "unknown"

    dirty = result.stdout.strip()
    if dirty:
        failures.append(Failure(
            rule="Git workspace is dirty.",
            why="A clean stop must not hide uncommitted source, handoff, proof, or generated files from the next agent.",
            fix=(
                "Finish the active slice, commit or deliberately stash/preserve the work, "
                "then rerun `git status --short --untracked-files=all` and `make clean-stop`.\n"
                f"Dirty paths:\n{dirty}"
            )
        ))
        return False, "dirty"

    return True, "clean"


def check_git_mirrored(failures: list[Failure]) -> tuple[bool, str]:
    upstream = run(["git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"])
    if upstream.returncode != 0:
        failures.append(Failure(
            rule="Git upstream is not configured.",
            why="A clean stop must know whether local HEAD is mirrored with the branch future agents will pull.",
            fix="Set or repair the upstream branch, or explicitly record why mirror status is not relevant before claiming a clean stop."
        ))
        return False, "not-checked"

    result = run(["git", "rev-list", "--left-right", "--count", "HEAD...@{u}"])
    if result.returncode != 0:
        failures.append(Failure(
            rule="Git mirror status could not be checked.",
            why="A clean stop must prove local HEAD is not ahead of or behind upstream.",
            fix=f"Repair the upstream ref and rerun `git rev-list --left-right --count HEAD...@{{u}}`. stderr: {result.stderr.strip()}"
        ))
        return False, "not-checked"

    counts = result.stdout.strip()
    if counts != "0\t0" and counts != "0 0":
        failures.append(Failure(
            rule="Git branch is not mirrored with upstream.",
            why="A future agent may pull a different state than the local handoff describes.",
            fix=(
                "Push committed local work or pull/rebase remote work, then rerun "
                "`git rev-list --left-right --count HEAD...@{u}` and `make clean-stop`.\n"
                f"Current ahead/behind counts: {counts}"
            )
        ))
        return False, counts

    return True, "mirrored"


def check_supervisor_stop(failures: list[Failure]) -> tuple[bool, str]:
    result = run(["python3", "automation/supervisor/run_next.py", "--dry-run"])
    output = "\n".join(part for part in [result.stdout.strip(), result.stderr.strip()] if part)
    expected = "stop: no eligible queued slice found."
    if result.returncode != 0:
        failures.append(Failure(
            rule="Supervisor dry-run failed.",
            why="A clean stop must prove the queue is valid enough for the supervisor to evaluate.",
            fix=f"Fix the supervisor/queue error, then rerun `python3 automation/supervisor/run_next.py --dry-run`.\n{output}"
        ))
        return False, output

    if expected not in result.stdout:
        failures.append(Failure(
            rule="Supervisor found eligible queued work.",
            why="A clean stop is not complete while the supervisor can start another actionable slice.",
            fix=f"Run or explicitly block/defer the selected slice, then rerun `make clean-stop`.\nSupervisor output:\n{output}"
        ))
        return False, output

    return True, expected


def check_queue_state(failures: list[Failure]) -> tuple[list[str], list[str], int]:
    try:
        queue_data = load_queue()
    except Exception as error:  # pragma: no cover - message path matters more than type here.
        failures.append(Failure(
            rule="Queue could not be loaded.",
            why="A clean stop must prove queue state, including parked work, from the versioned queue file.",
            fix=f"Fix `automation/queue/slices.json` or its schema, then rerun `make clean-stop`.\n{error}"
        ))
        return [], [], 0

    open_slices: list[str] = []
    parked_slices: list[str] = []
    done_count = 0

    for slice_record in queue_data.get("slices", []):
        status = slice_record.get("status", "")
        slice_id = slice_record.get("slice_id", "<missing-slice-id>")
        if status in OPEN_STATUSES:
            open_slices.append(f"{status} {slice_id}")
        elif status in PARKED_STATUSES:
            entry_condition = slice_record.get("entry_condition", "").strip()
            if not entry_condition:
                failures.append(Failure(
                    rule=f"Parked slice `{slice_id}` is missing `entry_condition`.",
                    why="Blocked/deferred work is only safe to leave parked when the next agent can tell what external condition unlocks it.",
                    fix="Add a concise `entry_condition` to the slice record, or convert the slice to `done` only if it is truly complete."
                ))
            parked_slices.append(f"{status} {slice_id}: {entry_condition or '<missing entry_condition>'}")
        elif status == "done":
            done_count += 1

    if open_slices:
        failures.append(Failure(
            rule="Queue still has open actionable slices.",
            why="A clean stop means all currently actionable slices are complete; queued/in-progress work still needs action.",
            fix="Run the queued slice, mark it blocked/deferred with an entry condition, or complete it before claiming clean stop.\nOpen slices:\n" + "\n".join(open_slices)
        ))

    return open_slices, parked_slices, done_count


def main() -> int:
    failures: list[Failure] = []

    _, git_clean = check_git_clean(failures)
    _, git_mirror = check_git_mirrored(failures)
    _, supervisor = check_supervisor_stop(failures)
    open_slices, parked_slices, done_count = check_queue_state(failures)

    print("Owlory Clean Stop Check")
    print()
    print(f"Git workspace: {git_clean}")
    print(f"Git mirror: {git_mirror}")
    print(f"Supervisor: {supervisor}")
    print(f"Open slices: {len(open_slices)}")
    print(f"Parked slices: {len(parked_slices)}")
    for item in parked_slices:
        print(f"  - {item}")
    print(f"Done slices: {done_count}")

    if failures:
        print()
        print("Result: not a clean stop", file=sys.stderr)
        for failure in failures:
            print(file=sys.stderr)
            print(f"Rule: {failure.rule}", file=sys.stderr)
            print(f"Why: {failure.why}", file=sys.stderr)
            print(f"Fix: {failure.fix}", file=sys.stderr)
        return 1

    print()
    print("Result: clean stop")
    print(
        "All currently actionable slices are complete: no open queue work, "
        "clean workspace, mirrored HEAD, and parked work has explicit entry conditions."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
