import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Sheet that shows the full build identity (version, build, commit, branch,
/// build date, configuration, bundle id) and offers a one-tap copy of the
/// diagnostic report. Bug reports without this block are unactionable; bug
/// reports with it can be reproduced by `git checkout <commit>`.
struct BuildInfoView: View {
    let info: BuildInfo
    var onDismiss: () -> Void

    @State private var didCopy = false

    init(info: BuildInfo = .current, onDismiss: @escaping () -> Void) {
        self.info = info
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Version") {
                    labeled("Version", info.marketingVersion)
                    labeled("Build", info.buildNumber)
                }
                Section("Source") {
                    labeled("Commit", info.gitCommit)
                    if info.gitCommitFull != info.gitCommit {
                        labeled("Full commit", info.gitCommitFull)
                    }
                    labeled("Branch", info.gitBranch)
                    if !info.gitTag.isEmpty {
                        labeled("Tag", info.gitTag)
                    }
                    if !info.rollbackGitReference.isEmpty && info.rollbackGitReference != "unknown" && info.rollbackGitReference != "no-git" {
                        labeled("Checkout", info.rollbackGitReference)
                    }
                    if !info.isReleaseable {
                        Label(
                            "Not releaseable — built from a dirty or unknown commit",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(OwloryColor.warning)
                    }
                }
                Section("Build") {
                    if !info.buildDate.isEmpty {
                        labeled("Built", info.buildDate)
                    }
                    if !info.buildConfiguration.isEmpty {
                        labeled("Configuration", info.buildConfiguration)
                    }
                    if !info.bundleIdentifier.isEmpty {
                        labeled("Bundle", info.bundleIdentifier)
                    }
                    if !info.buildNumberSource.isEmpty {
                        labeled("Build source", info.buildNumberSource)
                    }
                }
                Section {
                    Button {
                        copyDiagnosticReport()
                    } label: {
                        Label(
                            didCopy ? "Copied" : "Copy for bug report",
                            systemImage: didCopy ? "checkmark.circle.fill" : "doc.on.doc"
                        )
                    }
                    .accessibilityHint("Copies the full build identity to the clipboard so you can paste it into a bug report.")
                } footer: {
                    Text("Include this block when reporting a problem so the build can be reproduced exactly.")
                        .font(.caption)
                }
            }
            .navigationTitle("Build Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func labeled(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout.monospaced())
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func copyDiagnosticReport() {
        #if canImport(UIKit)
        UIPasteboard.general.string = info.diagnosticReport
        #endif
        didCopy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            didCopy = false
        }
    }
}
