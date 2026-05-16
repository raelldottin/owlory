import Foundation
import SwiftUI

struct WriteView: View {
    @ObservedObject var store: WriteStore
    @ObservedObject var todayStore: TodayStore
    @ObservedObject var homeStore: HomeStore
    @ObservedObject var patternStore: PatternStore
    var highlightedNoteID: UUID?
    var highlightedNoteSelectionID: UUID?
    var onHomeTaskSelected: (UUID) -> Void = { _ in }
    @State private var showingCapture = false
    @State private var captureTitle = ""
    @State private var captureBody = ""
    @State private var captureAudioFileName: String?
    @State private var captureAudioTranscription: String?
    @State private var captureBodyBeforeVoice: String?
    @State private var captureRecordID = UUID()
    @State private var selectedNote: WritingNote?
    @State private var lastPresentedHighlightedNoteSelectionID: UUID?
    @State private var isArchivedNotesExpanded = false

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
                    .accessibilityIdentifier("write.capture.entry")
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
                        Label {
                            Text("Capture a Note")
                        } icon: {
                            Image(systemName: "plus.circle")
                        }
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
                .accessibilityIdentifier("write.note.row.\(note.id.uuidString)")
            }
        } header: {
            HStack {
                Text(stage.localizedDisplayName)
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
            Section {
                DisclosureGroup("Archived Notes", isExpanded: $isArchivedNotesExpanded) {
                    ForEach(archived) { note in
                        Button {
                            selectedNote = note
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(note.body)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                        .continueHighlight(note.id == highlightedNoteID)
                        .id(note.id)
                        .swipeActions(edge: .leading) {
                            Button {
                                store.transitionStage(id: note.id, to: .capture)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(OwloryColor.brandPrimary)
                        }
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
    }

    // MARK: - Capture Sheet

    private var captureSheet: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $captureTitle)
                TextField("Body", text: $captureBody, axis: .vertical)
                    .lineLimit(3...8)
                Section("Voice Recording") {
                    VoiceCaptureButton(
                        recordID: captureRecordID,
                        onRecordingStarted: {
                            captureBodyBeforeVoice = captureBody
                            captureAudioTranscription = nil
                        },
                        onLiveTranscription: { text in
                            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                return
                            }
                            captureAudioTranscription = text
                            captureBody = VoiceTranscriptionRoutingRules.apply(
                                text,
                                to: captureBodyBeforeVoice ?? captureBody,
                                in: .writeCapture
                            )
                        }
                    ) { text, fileName in
                        captureAudioFileName = fileName
                        captureAudioTranscription = text
                        captureBody = VoiceTranscriptionRoutingRules.apply(
                            text,
                            to: captureBodyBeforeVoice ?? captureBody,
                            in: .writeCapture
                        )
                        captureBodyBeforeVoice = nil
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
        NoteDetailView(
            note: note,
            store: store,
            todayStore: todayStore,
            homeStore: homeStore,
            onHomeTaskSelected: onHomeTaskSelected,
            onDismiss: { selectedNote = nil }
        )
    }

    private func resetCapture() {
        captureTitle = ""
        captureBody = ""
        captureAudioFileName = nil
        captureAudioTranscription = nil
        captureBodyBeforeVoice = nil
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
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "write.row.accessibility.advanceHint",
                    comment: "Write note row accessibility hint when a next writing stage is available."
                ),
                next.localizedDisplayName
            )
        }

        return String(localized: "write.row.accessibility.defaultHint")
    }
}

// MARK: - Note Detail

private struct NoteDetailView: View {
    let note: WritingNote
    @ObservedObject var store: WriteStore
    @ObservedObject var todayStore: TodayStore
    @ObservedObject var homeStore: HomeStore
    let onHomeTaskSelected: (UUID) -> Void
    let onDismiss: () -> Void
    @State private var title: String
    @State private var bodyText: String
    @State private var stage: WritingStage
    @State private var showingSourceNoteSheet = false
    @State private var sourceType: WritingSourceType
    @State private var sourceTitle: String
    @State private var sourceCreator: String
    @State private var sourceURL: String
    @State private var sourceDate: String
    @State private var sourceCitation: String
    @State private var sourceQuote: String
    @State private var hasSourceMetadata: Bool
    @State private var showingDeleteConfirmation = false

    init(
        note: WritingNote,
        store: WriteStore,
        todayStore: TodayStore,
        homeStore: HomeStore,
        onHomeTaskSelected: @escaping (UUID) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.note = note
        self.store = store
        self.todayStore = todayStore
        self.homeStore = homeStore
        self.onHomeTaskSelected = onHomeTaskSelected
        self.onDismiss = onDismiss
        let sourceMetadata = note.sourceMetadata
        self._title = State(initialValue: note.title)
        self._bodyText = State(initialValue: note.body)
        self._stage = State(initialValue: note.stage)
        self._sourceType = State(initialValue: sourceMetadata?.type ?? .article)
        self._sourceTitle = State(initialValue: sourceMetadata?.sourceTitle ?? note.title)
        self._sourceCreator = State(initialValue: sourceMetadata?.creator ?? "")
        self._sourceURL = State(initialValue: sourceMetadata?.url ?? Self.firstURL(in: "\(note.title)\n\(note.body)"))
        self._sourceDate = State(initialValue: sourceMetadata?.sourceDate ?? "")
        self._sourceCitation = State(initialValue: sourceMetadata?.citation ?? "")
        self._sourceQuote = State(initialValue: sourceMetadata?.quote ?? "")
        self._hasSourceMetadata = State(initialValue: sourceMetadata != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextField("Title", text: $title)
                    TextField("Body", text: $bodyText, axis: .vertical)
                        .lineLimit(5...12)
                }
                promotionSection
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
                if stage == .source || hasSourceMetadata {
                    Section("Source") {
                        if hasSourceMetadata {
                            LabeledContent("Type", value: sourceType.localizedDisplayName)
                            if !sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                LabeledContent("Source Title", value: sourceTitle)
                            }
                            if !sourceCreator.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                LabeledContent("Author / Creator", value: sourceCreator)
                            }
                            if !sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                LabeledContent("URL", value: sourceURL)
                            }
                        } else {
                            Text("No source details yet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Button("Edit Source Details") {
                            prepareSourceNoteSheet()
                        }
                    }
                }
                Section("Stage") {
                    LabeledContent("Current", value: stage.localizedDisplayName)
                    if let next = WritingStageRules.nextStage(after: stage) {
                        Button(
                            String.localizedStringWithFormat(
                                NSLocalizedString(
                                    "write.stage.advanceTo",
                                    comment: "Button title for advancing a note to the next writing stage."
                                ),
                                next.localizedDisplayName
                            )
                        ) {
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
                if canOpenNoteOptions {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            if canAddToToday {
                                Button("Add to Today") {
                                    saveAndAddToToday()
                                }
                                .accessibilityIdentifier("write.note.action.addToToday.\(note.id.uuidString)")
                            }
                            if canTurnIntoTask {
                                Button("Turn into Task") {
                                    saveAndTurnIntoTask()
                                }
                            }
                            if canAddToProtocol {
                                Button("Add to Protocol") {
                                    saveAndAddToProtocol()
                                }
                            }
                            if canTurnIntoSourceNote {
                                Button(sourceNoteActionTitle) {
                                    prepareSourceNoteSheet()
                                }
                            }
                            if hasPromotionOptions {
                                Divider()
                            }
                            if canArchiveNote {
                                Button {
                                    saveAndArchiveNote()
                                } label: {
                                    Label("Archive Note", systemImage: "archivebox")
                                }
                            }
                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Note", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Note options")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateNote(id: note.id, title: title, body: bodyText)
                        onDismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSourceNoteSheet) {
                sourceNoteSheet
            }
            .confirmationDialog(
                "Delete this note?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Note", role: .destructive) {
                    deleteNote()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the note from Write. Archived notes can be kept without appearing in active stages.")
            }
            .accessibilityIdentifier("write.note.detail.\(note.id.uuidString)")
        }
    }

    private var hasPromotionOptions: Bool {
        canAddToToday || canTurnIntoTask || canAddToProtocol || canTurnIntoSourceNote
    }

    private var promotionSection: some View {
        Section {
            todayPromotionRow
            taskPromotionRow
            protocolPromotionRow
        } header: {
            Text("Move")
        } footer: {
            Text("Keep this note here. Move it only when useful.")
        }
    }

    private var todayPromotionRow: some View {
        promotionRow(
            title: "Today",
            systemImage: "sun.max",
            status: promotedTodayFocusItem == nil ? unpromotedStatus(canPromote: canAddToToday) : "In Today",
            actionTitle: promotedTodayFocusItem == nil && canAddToToday ? "Add" : nil,
            action: promotedTodayFocusItem == nil && canAddToToday ? saveAndAddToToday : nil
        )
    }

    private var taskPromotionRow: some View {
        promotionRow(
            title: "Task",
            systemImage: "checkmark.circle",
            status: promotedHomeTask == nil ? unpromotedStatus(canPromote: canTurnIntoTask) : "Created",
            actionTitle: taskPromotionActionTitle,
            action: taskPromotionAction
        )
    }

    private var protocolPromotionRow: some View {
        promotionRow(
            title: "Protocol",
            systemImage: "list.bullet.rectangle",
            status: promotedHomeProtocol == nil ? unpromotedStatus(canPromote: canAddToProtocol) : "Draft created",
            actionTitle: promotedHomeProtocol == nil && canAddToProtocol ? "Add" : nil,
            action: promotedHomeProtocol == nil && canAddToProtocol ? saveAndAddToProtocol : nil
        )
    }

    private var taskPromotionActionTitle: String? {
        if promotedHomeTask != nil {
            return "Show"
        }

        return canTurnIntoTask ? "Create" : nil
    }

    private var taskPromotionAction: (() -> Void)? {
        if let task = promotedHomeTask {
            return { saveAndShowHomeTask(task.id) }
        }

        return canTurnIntoTask ? saveAndTurnIntoTask : nil
    }

    private func promotionRow(
        title: String,
        systemImage: String,
        status: String,
        actionTitle: String?,
        action: (() -> Void)?
    ) -> some View {
        HStack(spacing: 12) {
            Label(title, systemImage: systemImage)
            Spacer()
            Text(status)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderless)
            }
        }
    }

    private func unpromotedStatus(canPromote: Bool) -> String {
        if canPromote {
            return "Ready"
        }

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Add a title first"
        }

        return "Unavailable"
    }

    private var canTurnIntoSourceNote: Bool {
        stage == .source || WritingStageRules.canTransition(from: stage, to: .source)
    }

    private var canArchiveNote: Bool {
        WritingStageRules.canTransition(from: stage, to: .archived)
    }

    private var canDeleteNote: Bool {
        true
    }

    private var canAddToToday: Bool {
        todayStore.canPromoteWritingNoteToToday(editedNote)
    }

    private var promotedTodayFocusItem: FocusItem? {
        todayStore.focusItemPromotedFromWritingNote(editedNote)
    }

    private var canTurnIntoTask: Bool {
        homeStore.canPromoteWritingNoteToTask(editedNote)
    }

    private var promotedHomeTask: HomeTask? {
        homeStore.taskPromotedFromWritingNote(editedNote)
    }

    private var canAddToProtocol: Bool {
        homeStore.canPromoteWritingNoteToProtocol(editedNote)
    }

    private var promotedHomeProtocol: HouseholdProtocol? {
        homeStore.protocolPromotedFromWritingNote(editedNote)
    }

    private var canOpenNoteOptions: Bool {
        hasPromotionOptions || canArchiveNote || canDeleteNote
    }

    private var sourceNoteActionTitle: String {
        stage == .source ? "Edit Source Details" : "Turn into Source Note"
    }

    private var sourceNoteSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Kind", selection: $sourceType) {
                        ForEach(WritingSourceType.allCases) { type in
                            Text(type.localizedDisplayName).tag(type)
                        }
                    }
                } header: {
                    Text("What kind of source is this?")
                } footer: {
                    Text("Owlory keeps your original note text and adds source fields quietly.")
                }

                Section("Source Details") {
                    TextField("Source title", text: $sourceTitle)
                    TextField("Author / creator", text: $sourceCreator)
                    TextField("URL", text: $sourceURL)
                        .textInputAutocapitalization(.never)
                        #if os(iOS)
                        .keyboardType(.URL)
                        #endif
                    TextField("Date accessed or created", text: $sourceDate)
                }

                Section("Optional Reference") {
                    TextField("Citation", text: $sourceCitation, axis: .vertical)
                        .lineLimit(2...5)
                    TextField("Quote", text: $sourceQuote, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .navigationTitle("Source Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingSourceNoteSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveSourceNote()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func prepareSourceNoteSheet() {
        if sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sourceTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sourceURL = Self.firstURL(in: "\(title)\n\(bodyText)")
        }
        showingSourceNoteSheet = true
    }

    private var editedNote: WritingNote {
        WritingNote(
            id: note.id,
            title: title,
            body: bodyText,
            stage: stage,
            createdDate: note.createdDate,
            audioFileName: note.audioFileName,
            audioTranscription: note.audioTranscription,
            sourceMetadata: note.sourceMetadata
        )
    }

    private func saveAndAddToToday() {
        let promotedNote = editedNote
        store.updateNote(id: note.id, title: title, body: bodyText)
        if todayStore.promoteWritingNoteToToday(promotedNote) {
            onDismiss()
        }
    }

    private func saveAndTurnIntoTask() {
        let promotedNote = editedNote
        store.updateNote(id: note.id, title: title, body: bodyText)
        if homeStore.promoteWritingNoteToTask(promotedNote) != nil {
            onDismiss()
        }
    }

    private func saveAndShowHomeTask(_ taskID: UUID) {
        store.updateNote(id: note.id, title: title, body: bodyText)
        onDismiss()
        onHomeTaskSelected(taskID)
    }

    private func saveAndAddToProtocol() {
        let promotedNote = editedNote
        store.updateNote(id: note.id, title: title, body: bodyText)
        if homeStore.promoteWritingNoteToProtocol(promotedNote) != nil {
            onDismiss()
        }
    }

    private func saveAndArchiveNote() {
        store.updateNote(id: note.id, title: title, body: bodyText)
        store.transitionStage(id: note.id, to: .archived)
        onDismiss()
    }

    private func deleteNote() {
        store.deleteNote(id: note.id)
        onDismiss()
    }

    private func saveSourceNote() {
        store.updateNote(id: note.id, title: title, body: bodyText)
        let metadata = WritingSourceMetadata(
            sourceTitle: sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            creator: sourceCreator.trimmingCharacters(in: .whitespacesAndNewlines),
            url: sourceURL.trimmingCharacters(in: .whitespacesAndNewlines),
            type: sourceType,
            sourceDate: sourceDate.trimmingCharacters(in: .whitespacesAndNewlines),
            citation: sourceCitation.trimmingCharacters(in: .whitespacesAndNewlines),
            quote: sourceQuote.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        if store.turnIntoSourceNote(id: note.id, metadata: metadata) {
            stage = .source
            hasSourceMetadata = true
            showingSourceNoteSheet = false
        }
    }

    private static func firstURL(in text: String) -> String {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return ""
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector.firstMatch(in: text, options: [], range: range)?.url?.absoluteString ?? ""
    }
}

private extension WritingStage {
    var localizedDisplayName: String {
        switch self {
        case .capture:
            return String(localized: "display.writingStage.capture")
        case .source:
            return String(localized: "display.writingStage.source")
        case .permanent:
            return String(localized: "display.writingStage.permanent")
        case .draftSeed:
            return String(localized: "display.writingStage.draftSeed")
        case .draft:
            return String(localized: "display.writingStage.draft")
        case .published:
            return String(localized: "display.writingStage.published")
        case .archived:
            return String(localized: "display.writingStage.archived")
        }
    }
}

private extension WritingSourceType {
    var localizedDisplayName: String {
        switch self {
        case .article:
            return String(localized: "display.writingSourceType.article")
        case .book:
            return String(localized: "display.writingSourceType.book")
        case .video:
            return String(localized: "display.writingSourceType.video")
        case .podcast:
            return String(localized: "display.writingSourceType.podcast")
        case .webpage:
            return String(localized: "display.writingSourceType.webpage")
        case .conversation:
            return String(localized: "display.writingSourceType.conversation")
        case .document:
            return String(localized: "display.writingSourceType.document")
        case .other:
            return String(localized: "display.writingSourceType.other")
        }
    }
}
