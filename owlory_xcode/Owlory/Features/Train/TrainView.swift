import SwiftUI

struct TrainView: View {
    @ObservedObject var store: TrainStore
    @ObservedObject var patternStore: PatternStore
    var highlightedSessionID: UUID?
    @State private var showingAddSession = false
    @State private var plannedActivity = ""
    @State private var isRecurring = false
    @State private var recurrenceDays = 1
    @State private var pendingDeleteSessionID: UUID?

    private var calibration: CalibrationRules.Calibration? {
        guard let snapshot = patternStore.weeklySnapshot else { return nil }
        return CalibrationRules.calibrate(
            todayEntry: DailyEntry(date: Date()),
            weeklySnapshot: snapshot
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                consistencySummarySection
                todaySection
                historySection
            }
            .scrollDismissesKeyboard(.interactively)
            .deleteConfirmation(L("Delete this session?"), item: $pendingDeleteSessionID) { id in
                store.deleteSession(id: id)
            }
            .navigationTitle("Train")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSession = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Plan training session")
                }
            }
            .sheet(isPresented: $showingAddSession) {
                addSessionSheet
            }
            .alert("Couldn't Update Session", isPresented: Binding(
                get: { store.lastError != nil },
                set: { if !$0 { store.lastError = nil } }
            )) {
                Button(L("OK"), role: .cancel) {}
            } message: {
                Text(store.lastError ?? "")
            }
            .sensoryFeedback(trigger: store.lastError != nil) { _, newValue in
                newValue ? .error : nil
            }
            .onAppear {
                proxy.scrollToContinueHighlight(highlightedSessionID)
            }
            .onChange(of: highlightedSessionID) { _, newValue in
                proxy.scrollToContinueHighlight(newValue)
            }
        }
    }

    // MARK: - Consistency Summary

    @ViewBuilder
    private var consistencySummarySection: some View {
        if let summary = calibration?.trainingSummary {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar")
                        .foregroundStyle(OwloryColor.brandPrimary)
                    Text(trainingConsistencySummaryMessage(for: summary))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func trainingConsistencySummaryMessage(for summary: CalibrationRules.TrainingConsistencySummary) -> String {
        let key: String
        switch summary.band {
        case .strong:
            key = "train.calibration.consistencySummary.strong"
        case .solid:
            key = "train.calibration.consistencySummary.solid"
        case .low:
            key = "train.calibration.consistencySummary.low"
        }

        return String.localizedStringWithFormat(
            NSLocalizedString(
                key,
                comment: "Train consistency summary with completion percent."
            ),
            summary.completionPercent
        )
    }

    // MARK: - Today

    private var todaySection: some View {
        Section {
            let todaySessions = store.activeTodaySessions
            if todaySessions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No sessions planned for today.")
                        .foregroundStyle(.secondary)
                    Button {
                        showingAddSession = true
                    } label: {
                        Label(L("Plan a Session"), systemImage: "plus.circle")
                    }
                }
            } else {
                ForEach(todaySessions) { session in
                    SessionCardView(
                        session: session,
                        store: store,
                        isHighlighted: session.id == highlightedSessionID
                    )
                    .id(session.id)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("train.session.item.\(session.id.uuidString)")
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            pendingDeleteSessionID = session.id
                        } label: {
                            Label(L("Delete"), systemImage: "trash")
                        }
                    }
                    .accessibilityActions {
                        Button(L("Delete"), role: .destructive) { pendingDeleteSessionID = session.id }
                    }
                }
                Button {
                    showingAddSession = true
                } label: {
                    Label(L("Add another session"), systemImage: "plus.circle")
                        .font(.subheadline)
                        .foregroundStyle(OwloryColor.brandPrimary)
                }
            }
        } header: {
            Text("Today")
        }
    }

    // MARK: - History

    @ViewBuilder
    private var historySection: some View {
        let history = store.historySessions
        if !history.isEmpty {
            Section {
                ForEach(history) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(session.plannedActivity)
                                .font(.subheadline.weight(.medium))
                            if session.isRecurring {
                                Image(systemName: "arrow.trianglehead.2.counterclockwise")
                                    .font(.caption2)
                                    .foregroundStyle(OwloryColor.brandPrimary)
                            }
                            Spacer()
                            StatusBadge(status: session.status)
                                .accessibilityIdentifier("train.session.history.status.\(session.status.rawValue).\(session.id.uuidString)")
                        }
                        Text(sessionDateString(session.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !session.reflection.isEmpty {
                            Text(session.reflection)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .continueHighlight(session.id == highlightedSessionID)
                    .id(session.id)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("train.session.history.item.\(session.id.uuidString)")
                }
            } header: {
                Text("History")
            }
        }
    }

    // MARK: - Add Session Sheet

    private var addSessionSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What's the session?", text: $plannedActivity)
                } header: {
                    Text("Plan")
                }
                Section {
                    Toggle("Repeat this session", isOn: $isRecurring)
                    if isRecurring {
                        Stepper(value: $recurrenceDays, in: 1...365) {
                            Text(RecurrenceIntervalPresentation.longLabel(days: recurrenceDays))
                        }
                    }
                }
            }
            .navigationTitle("Plan Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        resetAddSession()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Add")) {
                        store.addSession(
                            plannedActivity: plannedActivity,
                            isRecurring: isRecurring,
                            recurrenceIntervalDays: isRecurring ? recurrenceDays : nil
                        )
                        resetAddSession()
                    }
                    .disabled(plannedActivity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func resetAddSession() {
        plannedActivity = ""
        isRecurring = false
        recurrenceDays = 1
        showingAddSession = false
    }

    private static let sessionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private func sessionDateString(_ date: Date) -> String {
        Self.sessionDateFormatter.string(from: date)
    }
}

// MARK: - Session Card

private struct SessionCardView: View {
    let session: TrainingSession
    @ObservedObject var store: TrainStore
    let isHighlighted: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.isDuskActive) private var isDuskActive

    private var increasedContrast: Bool {
        colorSchemeContrast == .increased
    }
    @State private var actualActivity = ""
    @State private var reflection = ""
    @State private var status: TrainingStatus = .planned
    @State private var reflectionAudioFileName: String?
    @State private var reflectionAudioTranscription: String?
    @State private var reflectionCaptureID = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(session.plannedActivity)
                    .font(.headline)
                if session.isRecurring {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.trianglehead.2.counterclockwise")
                            .font(.caption2)
                        if let days = session.recurrenceIntervalDays {
                            Text(RecurrenceIntervalPresentation.longLabel(days: days))
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(OwloryColor.brandPrimary)
                }
                Spacer()
                StatusBadge(status: session.status)
            }

            if session.status == .planned {
                // What did you actually do?
                VStack(alignment: .leading, spacing: 4) {
                    Text("What did you actually do?")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("Describe the session", text: $actualActivity, axis: .vertical)
                        .font(.subheadline)
                }

                // Status
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    HStack(spacing: AppTheme.compactSpacing) {
                        ForEach(TrainingStatus.editableCases, id: \.rawValue) { s in
                            Button {
                                status = s
                            } label: {
                                Text(s.localizedDisplayName)
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        status == s
                                        ? OwloryAccessibilityContrast.tintedFill(
                                            statusPillColor(s, duskActive: isDuskActive),
                                            alpha: 0.22,
                                            reduceTransparency: reduceTransparency,
                                            increasedContrast: increasedContrast
                                        )
                                        : Color.clear
                                    )
                                    .foregroundStyle(status == s ? OwloryColor.textPrimary : .secondary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                status == s
                                                ? OwloryAccessibilityContrast.tintedBorder(
                                                    statusPillColor(s, duskActive: isDuskActive),
                                                    alpha: 0.65,
                                                    reduceTransparency: reduceTransparency,
                                                    increasedContrast: increasedContrast
                                                )
                                                : OwloryColor.borderSubtle,
                                                lineWidth: OwloryAccessibilityContrast.borderWidth(status == s ? 1.5 : 1, increasedContrast: increasedContrast)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                trainingStatusAccessibilityLabel(status: s, isSelected: status == s)
                            )
                            .accessibilityIdentifier("train.session.status.\(s.rawValue).\(session.id.uuidString)")
                        }
                    }
                }

                // Reflection
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reflection")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("How did it go?", text: $reflection, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(2...4)
                    VoiceCaptureButton(recordID: reflectionCaptureID) { text, fileName in
                        reflectionAudioFileName = fileName
                        reflectionAudioTranscription = text
                        reflection = VoiceTranscriptionRoutingRules.apply(
                            text,
                            to: reflection,
                            in: .trainSessionReflection
                        )
                    }
                    if let audioFile = reflectionAudioFileName {
                        HStack {
                            AudioPlaybackButton(fileName: audioFile)
                            Spacer()
                            Text("Recording saved")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let transcription = reflectionAudioTranscription, !transcription.isEmpty {
                        Text(transcription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button(L("Save")) {
                    store.updateSession(
                        id: session.id,
                        actualActivity: actualActivity,
                        status: status,
                        reflection: reflection,
                        reflectionAudioFileName: reflectionAudioFileName,
                        reflectionAudioTranscription: reflectionAudioTranscription
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityIdentifier("train.session.save.\(session.id.uuidString)")
                .disabled(status == .planned)
            } else {
                // What did you actually do?
                if !session.actualActivity.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("What did you actually do?")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.tertiary)
                        Text(session.actualActivity)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Status (shown via StatusBadge in header)

                // Reflection
                if !session.reflection.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reflection")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.tertiary)
                        HStack(alignment: .top) {
                            Text(session.reflection)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .italic()
                            if let audioFile = session.reflectionAudioFileName {
                                AudioPlaybackButton(fileName: audioFile)
                            }
                        }
                        if let transcription = session.reflectionAudioTranscription, !transcription.isEmpty {
                            Text(transcription)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .continueHighlight(isHighlighted)
        .onAppear {
            actualActivity = session.actualActivity
            reflection = session.reflection
            status = session.status
        }
    }
}

private func statusPillColor(_ status: TrainingStatus, duskActive: Bool = false) -> Color {
    switch status {
    case .planned: return OwloryColor.pillBorder(duskActive: duskActive)
    case .completed: return OwloryColor.success
    case .modified: return OwloryColor.warning
    case .skipped: return OwloryColor.error
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: TrainingStatus
    @Environment(\.isDuskActive) private var isDuskActive

    var body: some View {
        Text(status.localizedDisplayName)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.22))
            .foregroundStyle(OwloryColor.textPrimary)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(color.opacity(0.6), lineWidth: 1)
            )
            .accessibilityLabel(
                String.localizedStringWithFormat(
                    NSLocalizedString(
                        "display.trainingStatus.accessibility.status",
                        comment: "Accessibility label for a training session status badge."
                    ),
                    status.localizedDisplayName
                )
            )
    }

    private var color: Color {
        switch status {
        case .planned: return OwloryColor.pillBorder(duskActive: isDuskActive)
        case .completed: return OwloryColor.success
        case .modified: return OwloryColor.warning
        case .skipped: return OwloryColor.error
        }
    }
}

private func trainingStatusAccessibilityLabel(status: TrainingStatus, isSelected: Bool) -> String {
    let key = isSelected
        ? "display.trainingStatus.accessibility.selected"
        : "display.trainingStatus.accessibility"
    return String.localizedStringWithFormat(
        NSLocalizedString(
            key,
            comment: "Accessibility label for a selectable training session status."
        ),
        status.localizedDisplayName
    )
}

private extension TrainingStatus {
    var localizedDisplayName: String {
        switch self {
        case .planned:
            return String(localized: "display.trainingStatus.planned")
        case .completed:
            return String(localized: "display.trainingStatus.completed")
        case .modified:
            return String(localized: "display.trainingStatus.modified")
        case .skipped:
            return String(localized: "display.trainingStatus.skipped")
        }
    }
}
