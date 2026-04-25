import Foundation

/// Read-only snapshot of the build identity stamped into the app bundle's
/// Info.plist by `Tools/generate-build-info.sh`. Exposed both for in-app
/// "About" UI and for embedding into telemetry / bug reports.
///
/// Why this exists: every released archive must be traceable back to an exact
/// git commit. The TestFlight build number comes from Xcode's committed
/// `CURRENT_PROJECT_VERSION`; Git identifies the exact source to check out.
struct BuildInfo: Equatable {
    /// `CFBundleShortVersionString` — semantic marketing version (e.g. `0.2.0`).
    let marketingVersion: String

    /// `CFBundleVersion` — source-controlled Xcode build number.
    let buildNumber: String

    /// Short git SHA of the commit this build was archived from. Suffix
    /// `-dirty` indicates the working tree had uncommitted changes — those
    /// builds are NOT reproducible and should never reach TestFlight.
    let gitCommit: String

    /// Full git SHA of the commit this build was archived from. Suffix
    /// `-dirty` follows `gitCommit` and is stripped by `rollbackGitReference`.
    let gitCommitFull: String

    /// Branch name at archive time.
    let gitBranch: String

    /// Exact tag if one points at the commit, otherwise nearest git describe
    /// output. Useful when mapping TestFlight builds back to release tags.
    let gitTag: String

    /// ISO 8601 UTC timestamp of when the stamp script ran (≈ archive time).
    let buildDate: String

    /// `Debug`, `Release`, etc. — matches Xcode's `$CONFIGURATION`.
    let buildConfiguration: String

    /// `CFBundleIdentifier` — useful when triaging the right product (Owlory
    /// has shipped under multiple bundle IDs historically).
    let bundleIdentifier: String

    /// Human-readable provenance for `buildNumber`; normally Xcode's
    /// `CURRENT_PROJECT_VERSION`.
    let buildNumberSource: String

    /// Singleton snapshot from the running app's bundle. Cached because
    /// `Bundle.main.infoDictionary` is a syscall-backed lookup.
    static let current: BuildInfo = BuildInfo(bundle: .main)

    init(bundle: Bundle) {
        let info = bundle.infoDictionary ?? [:]
        self.init(
            marketingVersion: (info["CFBundleShortVersionString"] as? String) ?? "0.0.0",
            buildNumber: (info["CFBundleVersion"] as? String) ?? "0",
            gitCommit: (info["GitCommit"] as? String) ?? "unknown",
            gitCommitFull: (info["GitCommitFull"] as? String) ?? (info["GitCommit"] as? String) ?? "unknown",
            gitBranch: (info["GitBranch"] as? String) ?? "unknown",
            gitTag: (info["GitTag"] as? String) ?? "",
            buildDate: (info["BuildDate"] as? String) ?? "",
            buildConfiguration: (info["BuildConfiguration"] as? String) ?? "",
            bundleIdentifier: (info["CFBundleIdentifier"] as? String) ?? "",
            buildNumberSource: (info["BuildNumberSource"] as? String) ?? ""
        )
    }

    init(
        marketingVersion: String,
        buildNumber: String,
        gitCommit: String,
        gitCommitFull: String = "",
        gitBranch: String,
        gitTag: String = "",
        buildDate: String,
        buildConfiguration: String,
        bundleIdentifier: String,
        buildNumberSource: String = ""
    ) {
        self.marketingVersion = marketingVersion
        self.buildNumber = buildNumber
        self.gitCommit = gitCommit
        self.gitCommitFull = gitCommitFull.isEmpty ? gitCommit : gitCommitFull
        self.gitBranch = gitBranch
        self.gitTag = gitTag
        self.buildDate = buildDate
        self.buildConfiguration = buildConfiguration
        self.bundleIdentifier = bundleIdentifier
        self.buildNumberSource = buildNumberSource
    }

    // MARK: - Derived presentations

    /// Compact one-line summary, e.g. `v0.2.0 (47) · a1b2c3d4e5f6`.
    /// Suitable for telemetry log lines and footer chrome.
    var summary: String {
        "v\(marketingVersion) (\(buildNumber)) · \(gitCommit)"
    }

    /// Source reference to check out when reproducing or rolling back a build.
    /// Dirty suffixes are diagnostic metadata, not part of a valid git ref.
    var rollbackGitReference: String {
        let full = stripDirtySuffix(from: gitCommitFull)
        if !isMissingGitReference(full) {
            return full
        }
        return stripDirtySuffix(from: gitCommit)
    }

    /// Multi-line block intended for the in-app Copy-for-bug-report button.
    /// Format is stable so support can grep across reports.
    var diagnosticReport: String {
        var lines: [String] = []
        lines.append("Owlory \(marketingVersion) (\(buildNumber))")
        lines.append("Commit: \(gitCommit) on \(gitBranch)")
        if gitCommitFull != gitCommit {
            lines.append("Full commit: \(gitCommitFull)")
        }
        if !gitTag.isEmpty {
            lines.append("Tag: \(gitTag)")
        }
        if !isMissingGitReference(rollbackGitReference) {
            lines.append("Rollback: git checkout \(rollbackGitReference)")
        }
        if !buildDate.isEmpty {
            lines.append("Built:  \(buildDate) [\(buildConfiguration)]")
        } else if !buildConfiguration.isEmpty {
            lines.append("Built:  [\(buildConfiguration)]")
        }
        if !bundleIdentifier.isEmpty {
            lines.append("Bundle: \(bundleIdentifier)")
        }
        if !buildNumberSource.isEmpty {
            lines.append("Build number source: \(buildNumberSource)")
        }
        return lines.joined(separator: "\n")
    }

    /// `true` when the build was stamped from a clean git tree on a real
    /// archive — i.e. reproducible and safe to ship. Use this to gate any
    /// "submit to App Store" button or release-channel feature flag.
    var isReleaseable: Bool {
        guard !isMissingGitReference(rollbackGitReference) else {
            return false
        }
        return !gitCommit.hasSuffix("-dirty") && !gitCommitFull.hasSuffix("-dirty")
    }

    private func stripDirtySuffix(from value: String) -> String {
        value.hasSuffix("-dirty") ? String(value.dropLast("-dirty".count)) : value
    }

    private func isMissingGitReference(_ value: String) -> Bool {
        value.isEmpty || value == "unknown" || value == "no-git"
    }
}
