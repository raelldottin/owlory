import XCTest
@testable import Owlory

final class BuildInfoTests: XCTestCase {
    func test_summary_formatsVersionBuildAndCommit() {
        let info = BuildInfo(
            marketingVersion: "1.2.3",
            buildNumber: "47",
            gitCommit: "a1b2c3d4e5f6",
            gitBranch: "main",
            buildDate: "2026-04-15T08:00:00Z",
            buildConfiguration: "Release",
            bundleIdentifier: "com.raelldottin.owlory"
        )

        XCTAssertEqual(info.summary, "v1.2.3 (47) · a1b2c3d4e5f6")
    }

    func test_diagnosticReport_includesAllStableFields() {
        let info = BuildInfo(
            marketingVersion: "0.2.0",
            buildNumber: "12",
            gitCommit: "deadbeef1234",
            gitCommitFull: "deadbeef1234567890deadbeef1234567890abcd",
            gitBranch: "main",
            gitTag: "v0.2.0",
            gitStatus: "clean",
            buildDate: "2026-04-15T08:00:00Z",
            buildConfiguration: "Release",
            bundleIdentifier: "com.raelldottin.owlory",
            buildNumberSource: "Xcode CURRENT_PROJECT_VERSION"
        )

        let report = info.diagnosticReport
        XCTAssertTrue(report.contains("Owlory 0.2.0 (12)"))
        XCTAssertTrue(report.contains("Commit: deadbeef1234 on main"))
        XCTAssertTrue(report.contains("Full commit: deadbeef1234567890deadbeef1234567890abcd"))
        XCTAssertTrue(report.contains("Tag: v0.2.0"))
        XCTAssertTrue(report.contains("Git status: clean"))
        XCTAssertTrue(report.contains("Rollback: git checkout deadbeef1234567890deadbeef1234567890abcd"))
        XCTAssertTrue(report.contains("Built:  2026-04-15T08:00:00Z [Release]"))
        XCTAssertTrue(report.contains("Bundle: com.raelldottin.owlory"))
        XCTAssertTrue(report.contains("Build number source: Xcode CURRENT_PROJECT_VERSION"))
    }

    func test_initFromBundle_readsStampedGitStatus() throws {
        let bundleURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BuildInfoTests-\(UUID().uuidString)")
            .appendingPathExtension("bundle")
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: bundleURL) }

        let plist: [String: String] = [
            "CFBundleIdentifier": "com.raelldottin.owlory.tests",
            "CFBundlePackageType": "BNDL",
            "CFBundleShortVersionString": "1.0.0",
            "CFBundleVersion": "99",
            "GitCommit": "abc123def456",
            "GitCommitFull": "abc123def456abc123def456abc123def456abc1",
            "GitBranch": "main",
            "GitStatus": "clean"
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try data.write(to: bundleURL.appendingPathComponent("Info.plist"))

        let bundle = try XCTUnwrap(Bundle(url: bundleURL))
        let info = BuildInfo(bundle: bundle)

        XCTAssertEqual(info.gitStatus, "clean")
    }

    func test_rollbackGitReference_prefersFullCommitAndStripsDirtySuffix() {
        let info = BuildInfo(
            marketingVersion: "0.2.0",
            buildNumber: "20260417081904",
            gitCommit: "deadbeef1234-dirty",
            gitCommitFull: "deadbeef1234567890deadbeef1234567890abcd-dirty",
            gitBranch: "main",
            buildDate: "",
            buildConfiguration: "Debug",
            bundleIdentifier: ""
        )

        XCTAssertEqual(info.rollbackGitReference, "deadbeef1234567890deadbeef1234567890abcd")
        XCTAssertFalse(info.isReleaseable)
    }

    func test_diagnosticReport_omitsBuildLine_whenDateAndConfigBothEmpty() {
        let info = BuildInfo(
            marketingVersion: "0.2.0",
            buildNumber: "1",
            gitCommit: "abc",
            gitBranch: "main",
            buildDate: "",
            buildConfiguration: "",
            bundleIdentifier: ""
        )

        XCTAssertFalse(info.diagnosticReport.contains("Built:"))
    }

    func test_isReleaseable_isTrue_forCleanCommit() {
        let info = BuildInfo(
            marketingVersion: "0.2.0",
            buildNumber: "47",
            gitCommit: "a1b2c3d4",
            gitBranch: "main",
            buildDate: "",
            buildConfiguration: "Release",
            bundleIdentifier: ""
        )
        XCTAssertTrue(info.isReleaseable)
    }

    func test_isReleaseable_isFalse_forDirtyCommit() {
        let info = BuildInfo(
            marketingVersion: "0.2.0",
            buildNumber: "47",
            gitCommit: "a1b2c3d4-dirty",
            gitBranch: "main",
            buildDate: "",
            buildConfiguration: "Debug",
            bundleIdentifier: ""
        )
        XCTAssertFalse(info.isReleaseable)
    }

    func test_isReleaseable_isFalse_whenCommitMissing() {
        for sentinel in ["", "unknown", "no-git"] {
            let info = BuildInfo(
                marketingVersion: "0.2.0",
                buildNumber: "1",
                gitCommit: sentinel,
                gitBranch: "main",
                buildDate: "",
                buildConfiguration: "Debug",
                bundleIdentifier: ""
            )
            XCTAssertFalse(info.isReleaseable, "expected isReleaseable=false for commit '\(sentinel)'")
        }
    }

    func test_initFromBundle_fallsBackGracefully_whenInfoDictionaryIsEmpty() {
        // Use a bundle whose Info.plist does NOT contain our custom keys
        // (e.g. the test bundle itself) — the initializer must produce safe
        // defaults rather than crashing.
        let info = BuildInfo(bundle: Bundle(for: BuildInfoTests.self))
        XCTAssertFalse(info.marketingVersion.isEmpty)
        XCTAssertFalse(info.buildNumber.isEmpty)
        // Custom keys are not stamped into the test bundle.
        XCTAssertEqual(info.gitCommit, "unknown")
        XCTAssertEqual(info.gitBranch, "unknown")
        XCTAssertEqual(info.gitStatus, "unavailable")
    }
}
