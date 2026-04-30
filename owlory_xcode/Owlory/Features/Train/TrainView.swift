import SwiftUI

struct TrainView: View {
    @ObservedObject var store: TrainStore
    @ObservedObject var patternStore: PatternStore
    var highlightedSessionID: UUID?
    @State private var showingAddSession = false
    @State private var plannedActivity = ""
    @State private var readinessLevel = 3
    @State private var readinessNote = ""
    @State private var isRecurring = false
    @State private var recurrenceDays = 1

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
            .alert("Couldn't Update Train", isPresented: Binding(
                get: { store.lastError != nil },
                set: { if !$0 { store.lastError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.lastError ?? "")
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
                    Text(summary.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Today

    private var todaySection: some View {
        Section("Today") {
            let todaySessions = store.activeTodaySessions
            if todaySessions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No sessions planned for today.")
                        .foregroundStyle(.secondary)
                    Button {
                        showingAddSession = true
                    } label: {
                        Label("Plan a Session", systemImage: "plus.circle")
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
                }
                .onDelete { offsets in
                    let ids = offsets.map { todaySessions[$0].id }
                    for id in ids {
                        store.deleteSession(id: id)
                    }
                }
                Button {
                    showingAddSession = true
                } label: {
                    Label("Add another session", systemImage: "plus.circle")
                        .font(.subheadline)
                        .foregroundStyle(OwloryColor.brandPrimary)
                }
            }
        }
    }

    // MARK: - History

    @ViewBuilder
    private var historySection: some View {
        let history = store.historySessions
        if !history.isEmpty {
            Section("History") {
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
                }
            }
        }
    }

    // MARK: - Add Session Sheet

    private var addSessionSheet: some View {
        NavigationStack {
            Form {
                Section("Plan") {
                    TextField("What's the session?", text: $plannedActivity)
                }
                Section("Readiness") {
                    TrainingReadinessScaleRow(
                        label: "Training",
                        value: readinessLevel,
                        anchors: ("Low", "Okay", "High")
                    ) { value in
                        readinessLevel = value
                    }
                    TextField("Notes (optional)", text: $readinessNote, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section {
                    Toggle("Repeat this session", isOn: $isRecurring)
                    if isRecurring {
                        Stepper("Every \(recurrenceDays) \(recurrenceDays == 1 ? "day" : "days")", value: $recurrenceDays, in: 1...365)
                    }
                }
            }
            .navigationTitle("Plan Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetAddSession()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addSession(
                            plannedActivity: plannedActivity,
                            readinessLevel: readinessLevel,
                            readinessNote: readinessNote,
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
        readinessLevel = 3
        readinessNote = ""
        isRecurring = false
        recurrenceDays = 1
        showingAddSession = false
    }

    private func sessionDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Session Card

private struct SessionCardView: View {
    let session: TrainingSession
    @ObservedObject var store: TrainStore
    let isHighlighted: Bool
    @State private var actualActivity = ""
    @State private var readinessLevel = 3
    @State private var readinessNote = ""
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
                            Text("Every \(days)d")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(OwloryColor.brandPrimary)
                }
                Spacer()
                StatusBadge(status: session.status)
            }

            if session.status == .planned {
                TrainingReadinessScaleRow(
                    label: "Training",
                    value: readinessLevel,
                    anchors: ("Low", "Okay", "High")
                ) { value in
                    readinessLevel = value
                    store.updateReadinessLevel(id: session.id, readinessLevel: value)
                }

                TextField("Readiness notes (optional)", text: $readinessNote, axis: .vertical)
                    .font(.caption)
                    .lineLimit(1...3)
                    .onChange(of: readinessNote) { _ in
                        store.updateReadinessNote(id: session.id, readinessNote: readinessNote)
                    }

                Divider()

                TextField("What did you actually do?", text: $actualActivity, axis: .vertical)
                    .font(.subheadline)

                Picker("Status", selection: $status) {
                    ForEach(TrainingStatus.allCases, id: \.rawValue) { s in
                        Text(s.rawValue.capitalized).tag(s)
                    }
                }
                .pickerStyle(.segmented)

                TextField("Reflection", text: $reflection, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(2...4)

                Section {
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

                Button("Save") {
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
                .disabled(status == .planned)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "heart.text.square")
                        .foregroundStyle(trainingReadinessColor(for: session.readinessLevel))
                        .font(.caption)
                    Text("Readiness \(session.readinessLevel)/5")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !session.readinessNote.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "heart.text.square")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text(session.readinessNote)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if !session.actualActivity.isEmpty {
                    Text(session.actualActivity)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if !session.reflection.isEmpty && session.status != .planned {
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
        .continueHighlight(isHighlighted)
        .onAppear {
            readinessLevel = session.readinessLevel
            readinessNote = session.readinessNote
            actualActivity = session.actualActivity
            reflection = session.reflection
            status = session.status
        }
    }
}

struct TrainingReadinessScaleRow: View {
    let label: String
    let value: Int
    let anchors: (String, String, String)
    let onChange: (Int) -> Void

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                Label(label, systemImage: "heart.text.square")
                    .font(.subheadline)
                    .frame(width: 90, alignment: .leading)
                ForEach(1...5, id: \.self) { level in
                    Button {
                        onChange(level)
                    } label: {
                        Circle()
                            .fill(level <= value ? trainingReadinessColor(for: value) : OwloryColor.borderSubtle)
                            .frame(width: level == value ? 18 : 14, height: level == value ? 18 : 14)
                            .animation(.easeInOut(duration: 0.15), value: value)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("\(label) \(level) of 5\(level == value ? ", selected" : "")")
                }
            }
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 90)
                Text(anchors.0)
                    .frame(maxWidth: .infinity)
                Text("")
                    .frame(maxWidth: .infinity)
                Text(anchors.1)
                    .frame(maxWidth: .infinity)
                Text("")
                    .frame(maxWidth: .infinity)
                Text(anchors.2)
                    .frame(maxWidth: .infinity)
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
    }
}

func trainingReadinessColor(for value: Int) -> Color {
    switch value {
    case 1...2: return OwloryColor.error
    case 3: return OwloryColor.warning
    case 4...5: return OwloryColor.success
    default: return OwloryColor.textTertiary
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: TrainingStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .accessibilityLabel("Status: \(status.rawValue)")
    }

    private var color: Color {
        switch status {
        case .planned: return OwloryColor.brandPrimary
        case .completed: return OwloryColor.success
        case .modified: return OwloryColor.warning
        case .skipped: return OwloryColor.error
        }
    }
}
