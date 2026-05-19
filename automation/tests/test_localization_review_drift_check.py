import importlib.util
import json
import plistlib
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
                {
                    "key": "x.plural",
                    "plural_variable": "var",
                    "plural_category": "one",
                    "english_value": "v",
                    "resource_type": "stringsdict",
                },
            ]
        }
        with TemporaryDirectory() as temp_dir:
            return_path = Path(temp_dir) / "ar-review-return.json"
            return_path.write_text(json.dumps(return_payload), encoding="utf-8")
            with mock.patch.object(drift, "return_file_for", return_value=return_path):
                report = drift.analyze_locale(
                    "ar",
                    source_strings={"Today": "Today", "Save": "Save"},
                    source_stringsdict_entries={("x.plural", "var", "one"): "v"},
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
                    source_stringsdict_entries={},
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
                    source_stringsdict_entries={},
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
                    source_stringsdict_entries={},
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


class ParseStringsdictKeysTests(unittest.TestCase):
    def test_returns_empty_set_when_file_missing(self):
        self.assertEqual(drift.parse_stringsdict_keys(Path("/no/such/path")), set())

    def test_parses_xml_plist_via_plistlib_without_plutil(self):
        with TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "Localizable.stringsdict"
            with path.open("wb") as handle:
                plistlib.dump({"x.plural": {"a": "%d items"}, "y.plural": {"b": 1}}, handle)

            # Confirm plistlib succeeds even when plutil is unavailable.
            with mock.patch("shutil.which", return_value=None):
                keys = drift.parse_stringsdict_keys(path)

            self.assertEqual(keys, {"x.plural", "y.plural"})

    def test_raises_when_plistlib_fails_and_plutil_missing(self):
        with TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "Localizable.stringsdict"
            path.write_text("not a plist file at all", encoding="utf-8")

            with mock.patch("shutil.which", return_value=None):
                with self.assertRaises(drift.StringsdictParseError) as ctx:
                    drift.parse_stringsdict_keys(path)

            self.assertIn("plutil is not on PATH", str(ctx.exception))

    def test_falls_back_to_plutil_when_plistlib_rejects_format(self):
        with TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "Localizable.stringsdict"
            path.write_text("not xml or binary plist", encoding="utf-8")

            class FakeResult:
                returncode = 0
                stdout = '{"a.key": {}, "b.key": {}}'
                stderr = ""

            with mock.patch("shutil.which", return_value="/usr/bin/plutil"):
                with mock.patch("subprocess.run", return_value=FakeResult()):
                    keys = drift.parse_stringsdict_keys(path)

            self.assertEqual(keys, {"a.key", "b.key"})

    def test_raises_when_plutil_fails(self):
        with TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "Localizable.stringsdict"
            path.write_text("not a plist", encoding="utf-8")

            class FakeResult:
                returncode = 1
                stdout = ""
                stderr = "plutil: not a valid plist"

            with mock.patch("shutil.which", return_value="/usr/bin/plutil"):
                with mock.patch("subprocess.run", return_value=FakeResult()):
                    with self.assertRaises(drift.StringsdictParseError) as ctx:
                        drift.parse_stringsdict_keys(path)

            self.assertIn("plutil exited 1", str(ctx.exception))


class ParseStringsdictEntriesTests(unittest.TestCase):
    def test_returns_empty_when_file_missing(self):
        self.assertEqual(drift.parse_stringsdict_entries(Path("/no/such/path")), {})

    def test_enumerates_key_plural_variable_plural_category_tuples(self):
        payload = {
            "today.dashboard.train.summary": {
                "NSStringLocalizedFormatKey": "%#@planned@",
                "planned": {
                    "NSStringFormatSpecTypeKey": "NSStringPluralRuleType",
                    "NSStringFormatValueTypeKey": "d",
                    "one": "%d planned",
                    "other": "%d planned",
                },
            },
        }
        with TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "Localizable.stringsdict"
            with path.open("wb") as handle:
                plistlib.dump(payload, handle)

            entries = drift.parse_stringsdict_entries(path)

            self.assertEqual(entries, {
                ("today.dashboard.train.summary", "planned", "one"): "%d planned",
                ("today.dashboard.train.summary", "planned", "other"): "%d planned",
            })

    def test_skips_metadata_keys_inside_plural_dicts(self):
        payload = {
            "x.plural": {
                "var": {
                    "NSStringFormatSpecTypeKey": "NSStringPluralRuleType",
                    "NSStringFormatValueTypeKey": "d",
                    "one": "one item",
                },
            },
        }
        with TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "Localizable.stringsdict"
            with path.open("wb") as handle:
                plistlib.dump(payload, handle)

            entries = drift.parse_stringsdict_entries(path)

            self.assertEqual(entries, {("x.plural", "var", "one"): "one item"})


class AnalyzeLocaleStringsdictDriftTests(unittest.TestCase):
    def test_detects_missing_plural_tuple(self):
        return_payload = {
            "resources": [
                {
                    "key": "x.plural",
                    "plural_variable": "var",
                    "plural_category": "one",
                    "english_value": "one item",
                    "resource_type": "stringsdict",
                },
            ]
        }
        with TemporaryDirectory() as temp_dir:
            return_path = Path(temp_dir) / "ar-review-return.json"
            return_path.write_text(json.dumps(return_payload), encoding="utf-8")
            with mock.patch.object(drift, "return_file_for", return_value=return_path):
                report = drift.analyze_locale(
                    "ar",
                    source_strings={},
                    source_stringsdict_entries={
                        ("x.plural", "var", "one"): "one item",
                        ("x.plural", "var", "other"): "%d items",
                    },
                )

        self.assertEqual(report["status"], "drift")
        self.assertEqual(report["missing_stringsdict_tuples"], [["x.plural", "var", "other"]])
        self.assertEqual(report["drift_count"], 1)

    def test_detects_stale_plural_tuple(self):
        return_payload = {
            "resources": [
                {
                    "key": "x.plural",
                    "plural_variable": "var",
                    "plural_category": "one",
                    "english_value": "one item",
                    "resource_type": "stringsdict",
                },
                {
                    "key": "x.plural",
                    "plural_variable": "var",
                    "plural_category": "removed-category",
                    "english_value": "old",
                    "resource_type": "stringsdict",
                },
            ]
        }
        with TemporaryDirectory() as temp_dir:
            return_path = Path(temp_dir) / "fr-review-return.json"
            return_path.write_text(json.dumps(return_payload), encoding="utf-8")
            with mock.patch.object(drift, "return_file_for", return_value=return_path):
                report = drift.analyze_locale(
                    "fr",
                    source_strings={},
                    source_stringsdict_entries={
                        ("x.plural", "var", "one"): "one item",
                    },
                )

        self.assertEqual(report["status"], "drift")
        self.assertEqual(
            report["stale_stringsdict_tuples"],
            [["x.plural", "var", "removed-category"]],
        )
        self.assertEqual(report["drift_count"], 1)

    def test_detects_changed_stringsdict_english_value(self):
        return_payload = {
            "resources": [
                {
                    "key": "x.plural",
                    "plural_variable": "var",
                    "plural_category": "one",
                    "english_value": "stale english",
                    "resource_type": "stringsdict",
                },
            ]
        }
        with TemporaryDirectory() as temp_dir:
            return_path = Path(temp_dir) / "es-review-return.json"
            return_path.write_text(json.dumps(return_payload), encoding="utf-8")
            with mock.patch.object(drift, "return_file_for", return_value=return_path):
                report = drift.analyze_locale(
                    "es",
                    source_strings={},
                    source_stringsdict_entries={
                        ("x.plural", "var", "one"): "fresh english",
                    },
                )

        self.assertEqual(report["status"], "drift")
        self.assertEqual(report["changed_stringsdict_english_values"], [{
            "key": "x.plural",
            "plural_variable": "var",
            "plural_category": "one",
            "source_value": "fresh english",
            "return_file_value": "stale english",
        }])
        self.assertEqual(report["drift_count"], 1)

    def test_no_drift_when_stringsdict_tuples_match(self):
        return_payload = {
            "resources": [
                {
                    "key": "x.plural",
                    "plural_variable": "var",
                    "plural_category": "one",
                    "english_value": "one item",
                    "resource_type": "stringsdict",
                },
                {
                    "key": "x.plural",
                    "plural_variable": "var",
                    "plural_category": "other",
                    "english_value": "%d items",
                    "resource_type": "stringsdict",
                },
            ]
        }
        with TemporaryDirectory() as temp_dir:
            return_path = Path(temp_dir) / "ja-review-return.json"
            return_path.write_text(json.dumps(return_payload), encoding="utf-8")
            with mock.patch.object(drift, "return_file_for", return_value=return_path):
                report = drift.analyze_locale(
                    "ja",
                    source_strings={},
                    source_stringsdict_entries={
                        ("x.plural", "var", "one"): "one item",
                        ("x.plural", "var", "other"): "%d items",
                    },
                )

        self.assertEqual(report["status"], "ok")
        self.assertEqual(report["drift_count"], 0)


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
