import importlib.util
import json
import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest import mock


def _load_drift_module():
    repo_root = Path(__file__).resolve().parents[2]
    path = repo_root / "Tools" / "localization-review-drift-check.py"
    spec = importlib.util.spec_from_file_location("localization_review_drift_check", path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules["localization_review_drift_check"] = module
    spec.loader.exec_module(module)
    return module


drift = _load_drift_module()


class ParseStringsFileTests(unittest.TestCase):
    def test_parses_simple_pairs(self):
        with TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "Localizable.strings"
            path.write_text(
                '"Today" = "Today";\n"Save" = "Save";\n', encoding="utf-8"
            )

            pairs = drift.parse_strings_file(path)

            self.assertEqual(pairs, {"Today": "Today", "Save": "Save"})

    def test_returns_empty_when_file_missing(self):
        self.assertEqual(drift.parse_strings_file(Path("/no/such/path")), {})

    def test_unescapes_escaped_quotes(self):
        with TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "Localizable.strings"
            path.write_text(
                '"talk.title" = "She said \\"hello\\"";\n', encoding="utf-8"
            )

            pairs = drift.parse_strings_file(path)

            self.assertEqual(pairs["talk.title"], 'She said "hello"')


class AnalyzeLocaleTests(unittest.TestCase):
    def test_no_drift_when_keys_and_english_match(self):
        return_payload = {
            "resources": [
                {"key": "Today", "english_value": "Today", "resource_type": "strings"},
                {"key": "Save", "english_value": "Save", "resource_type": "strings"},
                {"key": "x.plural", "english_value": "%d items", "resource_type": "stringsdict"},
            ]
        }
        with TemporaryDirectory() as temp_dir:
            return_path = Path(temp_dir) / "ar-review-return.json"
            return_path.write_text(json.dumps(return_payload), encoding="utf-8")
            with mock.patch.object(drift, "return_file_for", return_value=return_path):
                report = drift.analyze_locale(
                    "ar",
                    source_strings={"Today": "Today", "Save": "Save"},
                    source_stringsdict_keys={"x.plural"},
                )

        self.assertEqual(report["status"], "ok")
        self.assertEqual(report["drift_count"], 0)

    def test_flags_missing_source_keys(self):
        return_payload = {
            "resources": [
                {"key": "Today", "english_value": "Today", "resource_type": "strings"},
            ]
        }
        with TemporaryDirectory() as temp_dir:
            return_path = Path(temp_dir) / "fr-review-return.json"
            return_path.write_text(json.dumps(return_payload), encoding="utf-8")
            with mock.patch.object(drift, "return_file_for", return_value=return_path):
                report = drift.analyze_locale(
                    "fr",
                    source_strings={"Today": "Today", "NewKey": "New copy"},
                    source_stringsdict_keys=set(),
                )

        self.assertEqual(report["status"], "drift")
        self.assertEqual(report["missing_strings_keys"], ["NewKey"])
        self.assertEqual(report["drift_count"], 1)

    def test_flags_stale_return_entries(self):
        return_payload = {
            "resources": [
                {"key": "Today", "english_value": "Today", "resource_type": "strings"},
                {"key": "Removed", "english_value": "Removed", "resource_type": "strings"},
            ]
        }
        with TemporaryDirectory() as temp_dir:
            return_path = Path(temp_dir) / "ja-review-return.json"
            return_path.write_text(json.dumps(return_payload), encoding="utf-8")
            with mock.patch.object(drift, "return_file_for", return_value=return_path):
                report = drift.analyze_locale(
                    "ja",
                    source_strings={"Today": "Today"},
                    source_stringsdict_keys=set(),
                )

        self.assertEqual(report["status"], "drift")
        self.assertEqual(report["stale_strings_keys"], ["Removed"])
        self.assertEqual(report["drift_count"], 1)

    def test_flags_changed_english_value(self):
        return_payload = {
            "resources": [
                {"key": "Save", "english_value": "Save", "resource_type": "strings"},
            ]
        }
        with TemporaryDirectory() as temp_dir:
            return_path = Path(temp_dir) / "es-review-return.json"
            return_path.write_text(json.dumps(return_payload), encoding="utf-8")
            with mock.patch.object(drift, "return_file_for", return_value=return_path):
                report = drift.analyze_locale(
                    "es",
                    source_strings={"Save": "Save changes"},
                    source_stringsdict_keys=set(),
                )

        self.assertEqual(report["status"], "drift")
        self.assertEqual(report["changed_english_values"], [
            {"key": "Save", "source_value": "Save changes", "return_file_value": "Save"}
        ])
        self.assertEqual(report["drift_count"], 1)

    def test_missing_return_file_is_flagged(self):
        with mock.patch.object(drift, "return_file_for", return_value=Path("/no/such/path")):
            report = drift.analyze_locale("xx", {}, set())

        self.assertEqual(report["status"], "missing-return-file")


class CheckExitCodeTests(unittest.TestCase):
    def test_check_exits_nonzero_on_drift(self):
        with TemporaryDirectory() as temp_dir:
            review_dir = Path(temp_dir) / "review"
            review_dir.mkdir()
            (review_dir / "ar").mkdir()
            (review_dir / "ar" / "ar-review-return.json").write_text(
                json.dumps({"resources": []}), encoding="utf-8"
            )
            with mock.patch.object(drift, "REVIEW_DIR", review_dir):
                with mock.patch.object(drift, "parse_strings_file", return_value={"K": "V"}):
                    with mock.patch.object(drift, "parse_stringsdict_keys", return_value=set()):
                        rc = drift.main(["--check", "--locales", "ar"])

        self.assertEqual(rc, 1)

    def test_reporting_only_exits_zero_on_drift(self):
        with TemporaryDirectory() as temp_dir:
            review_dir = Path(temp_dir) / "review"
            review_dir.mkdir()
            (review_dir / "ar").mkdir()
            (review_dir / "ar" / "ar-review-return.json").write_text(
                json.dumps({"resources": []}), encoding="utf-8"
            )
            with mock.patch.object(drift, "REVIEW_DIR", review_dir):
                with mock.patch.object(drift, "parse_strings_file", return_value={"K": "V"}):
                    with mock.patch.object(drift, "parse_stringsdict_keys", return_value=set()):
                        rc = drift.main(["--locales", "ar"])

        self.assertEqual(rc, 0)


if __name__ == "__main__":
    unittest.main()
