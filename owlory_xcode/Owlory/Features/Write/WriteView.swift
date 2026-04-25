import SwiftUI

struct WriteView: View {
    @ObservedObject var store: WriteStore
    @ObservedObject var patternStore: PatternStore
    var highlightedNoteID: UUID?
    var highlightedNoteSelectionID: UUID?
    @State private var showingCapture = false
    @State private var captureTitle = ""
    @State private var captureBody = ""
    @State private var captureAudioFileName: String?
    @State private var captureAudioTranscription: String?
    @State private var captureRecordID = UUID()
    @State private var selectedNote: WritingNote?
    @State private var lastPresentedHighlightedNoteSelectionID: UUID?

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
                pipelineNudgeSection
                captureSection
                ForEach(activeStages, id: \.self) { stage in
                    stageSection(stage)
                }
                archiveSection
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Write")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCapture = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Capture new note")
                }
            }
            .sheet(isPresented: $showingCapture) {
                captureSheet
            }
            .sheet(item: $selectedNote) { note in
                noteDetailSheet(note)
            }
            .alert("Couldn't Update Write", isPresented: Binding(
                get: { store.lastError != nil },
                set: { if !$0 { store.lastError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.lastError ?? "")
            }
            .onAppear {
                presentHighlightedNoteIfNeeded()
                proxy.scrollToContinueHighlight(highlightedNoteID)
            }
            .onChange(of: highlightedNoteSelectionID) { _, _ in
                presentHighlightedNoteIfNeeded()
            }
            .onChange(of: highlightedNoteID) { _, newValue in
                proxy.scrollToContinueHighlight(newValue)
            }
        }
    }

    // MARK: - Pipeline Nudge

    @ViewBuilder
    private var pipelineNudgeSection: some View {
        if let nudge = calibration?.writingNudge {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.right.circle")
                        .foregroundStyle(OwloryColor.brandPrimary)
                    Text(nudge.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Active Stages (non-terminal, non-archived)

    private var activeStages: [WritingStage] {
        WritingStage.allCases.filter { stage in
            stage != .archived && !(store.notesByStage[stage] ?? []).isEmpty
        }
    }

    // MARK: - Capture Section (quick add at top)

    @ViewBuilder
    private var captureSection: some View {
        let captures = store.notesByStage[.capture] ?? []
        if captures.isEmpty && store.notes.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No notes yet.")
                        .foregroundStyle(.secondary)
                    Text("Capture -> Source -> Permanent -> Draft Seed -> Draft -> Published")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Button {
                        showingCapture = true
                    } label: {
                        Label("Capture a Note", systemImage: "plus.circle")
                    }
                }
            }
        }
    }

    // MARK: - Stage Section

    private func stageSection(_ stage: WritingStage) -> some View {
        Section {
            ForEach(store.notesByStage[stage] ?? []) { note in
                Button {
                    selectedNote = note
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            if !note.body.isEmpty {
                                Text(note.body)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        Spacer()
                        if note.audioFileName != nil {
                            Image(systemName: "waveform")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .continueHighlight(note.id == highlightedNoteID)
                .id(note.id)
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    if WritingStageRules.nextStage(after: stage) != nil {
                        Button {
                            store.advanceStage(id: note.id)
                        } label: {
                            Label("Advance", systemImage: "arrow.right.circle")
                        }
                        .tint(OwloryColor.brandPrimary)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        store.deleteNote(id: note.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    if WritingStageRules.canTransition(from: stage, to: .archived) {
                        Button {
                            store.transitionStage(id: note.id, to: .archived)
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(OwloryColor.textTertiary)
                    }
                }
                .accessibilityHint(writeRowAccessibilityHint(for: note))
            }
        } header: {
            HStack {
                Text(stage.title)
                Spacer()
                Text("\((store.notesByStage[stage] ?? []).count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Archive

    @ViewBuilder
    private var archiveSection: some View {
        let archived = store.notesByStage[.archived] ?? []
        if !archived.isEmpty {
            Section("Archived") {
                ForEach(archived) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(note.body)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    .continueHighlight(note.id == highlightedNoteID)
                    .id(note.id)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.deleteNote(id: note.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Capture Sheet

    private var captureSheet: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $captureTitle)
                TextField("Body", text: $captureBody, axis: .vertical)
                    .lineLimit(3...8)
                Section("Voice Recording") {
                    VoiceCaptureButton(recordID: captureRecordID) { text, fileName in
                        captureAudioFileName = fileName
                        captureAudioTranscription = text
                        captureBody = VoiceTranscriptionRoutingRules.apply(
                            text,
                            to: captureBody,
                            in: .writeCapture
                        )
                    }
                    if let audioFile = captureAudioFileName {
                        HStack {
                            AudioPlaybackButton(fileName: audioFile)
                            Spacer()
                            Text("Recording saved")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let transcription = captureAudioTranscription, !transcription.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Transcription")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text(transcription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Capture Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetCapture()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addNote(
                            title: captureTitle,
                            body: captureBody,
                            audioFileName: captureAudioFileName,
                            audioTranscription: captureAudioTranscription
                        )
                        resetCapture()
                    }
                    .disabled(captureTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Note Detail Sheet

    private func noteDetailSheet(_ note: WritingNote) -> some View {
        NoteDetailView(note: note, store: store, onDismiss: { selectedNote = nil })
    }

    private func resetCapture() {
        captureTitle = ""
        captureBody = ""
        captureAudioFileName = nil
        captureAudioTranscription = nil
        captureRecordID = UUID()
        showingCapture = false
    }

    private func presentHighlightedNoteIfNeeded() {
        guard let noteID = WriteContinueRouting.highlightedNoteToPresent(
            highlightedNoteID: highlightedNoteID,
            requestID: highlightedNoteSelectionID,
            lastPresentedRequestID: lastPresentedHighlightedNoteSelectionID,
            availableNoteIDs: Set(store.notes.map(\.id))
        ),
        let note = store.notes.first(where: { $0.id == noteID }) else {
            return
        }

        lastPresentedHighlightedNoteSelectionID = highlightedNoteSelectionID
        selectedNote = note
    }

    private func writeRowAccessibilityHint(for note: WritingNote) -> String {
        if let next = WritingStageRules.nextStage(after: note.stage) {
            return "Opens note details. Swipe for actions, including advance to \(next.title)."
        }

        return "Opens note details. Swipe for actions."
    }
}

// MARK: - Note Detail

private struct NoteDetailView: View {
    let note: WritingNote
    @ObservedObject var store: WriteStore
    let onDismiss: () -> Void
    @State private var title: String
    @State private var bodyText: String

    init(note: WritingNote, store: WriteStore, onDismiss: @escaping () -> Void) {
        self.note = note
        self.store = store
        self.onDismiss = onDismiss
        self._title = State(initialValue: note.title)
        self._bodyText = State(initialValue: note.body)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextField("Title", text: $title)
                    TextField("Body", text: $bodyText, axis: .vertical)
                        .lineLimit(5...12)
                }
                if let audioFile = note.audioFileName {
                    Section("Voice Recording") {
                        HStack {
                            Text("Recording")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            AudioPlaybackButton(fileName: audioFile)
                        }
                        if let transcription = note.audioTranscription, !transcription.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Transcription")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                                Text(transcription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Stage") {
                    LabeledContent("Current", value: note.stage.title)
                    if let next = WritingStageRules.nextStage(after: note.stage) {
                        Button("Advance to \(next.title)") {
                            store.advanceStage(id: note.id)
                            onDismiss()
                        }
                    }
                }
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateNote(id: note.id, title: title, body: bodyText)
                        onDismiss()
                    }
                }
            }
        }
    }
}
