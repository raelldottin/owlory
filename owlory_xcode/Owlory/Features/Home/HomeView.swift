import SwiftUI

struct HomeView: View {
    @ObservedObject var store: HomeStore
    @ObservedObject var writeStore: WriteStore
    var highlightedTaskID: UUID?
    var highlightedRunID: UUID?
    var highlightedRunSelectionID: UUID?
    let onSourceNoteSelected: (UUID) -> Void
    @State private var showingAddTask = false
    @State private var showingAddProtocol = false
    @State private var editingTask: HomeTask?
    @State private var editingProtocol: HouseholdProtocol?

    @State private var activeRunID: UUID?
    @State private var lastPresentedHighlightedRunSelectionID: UUID?
    @State private var isCompletedTasksExpanded = false
    @State private var isRecentRunsExpanded = false
    @State private var isArchivedProtocolsExpanded = false

    var body: some View {
        ScrollViewReader { proxy in
            List {
                activeRunsSection
                activeTasksSection
                skippedTasksSection
                completedTasksSection
                protocolsSection
                archivedProtocolsSection
                completedRunsSection
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddTask = true
                        } label: {
                            Label("Add Task", systemImage: "checklist")
                        }
                        Button {
                            showingAddProtocol = true
                        } label: {
                            Label("Add Protocol", systemImage: "list.clipboard")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add task or protocol")
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskSheet(store: store, onDismiss: { showingAddTask = false })
            }
            .sheet(isPresented: $showingAddProtocol) {
                AddProtocolSheet(store: store, onDismiss: { showingAddProtocol = false })
            }
            .sheet(item: $editingTask) { task in
                EditTaskSheet(
                    task: task,
                    store: store,
                    sourceNoteRoute: HomeTaskSourceRouting.writeNoteRoute(
                        for: task,
                        writingNotes: writeStore.notes
                    ),
                    onViewSourceNote: { noteID in
                        editingTask = nil
                        onSourceNoteSelected(noteID)
                    },
                    onDismiss: { editingTask = nil }
                )
            }
            .sheet(item: $editingProtocol) { proto in
                EditProtocolSheet(
                    proto: proto,
                    store: store,
                    sourceNoteRoute: HomeProtocolSourceRouting.writeNoteRoute(
                        for: proto,
                        writingNotes: writeStore.notes
                    ),
                    onViewSourceNote: { noteID in
                        editingProtocol = nil
                        onSourceNoteSelected(noteID)
                    },
                    onDismiss: { editingProtocol = nil }
                )
            }
            .sheet(isPresented: Binding(
                get: { activeRunID != nil },
                set: { if !$0 { activeRunID = nil } }
            )) {
                if let runID = activeRunID, let run = store.runs.first(where: { $0.id == runID }) {
                    ProtocolRunSheet(run: run, store: store, onDismiss: { activeRunID = nil })
                }
            }
            .alert("Couldn't Update Home", isPresented: Binding(
                get: { store.lastError != nil },
                set: { if !$0 { store.lastError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.lastError ?? "")
            }
            .onAppear {
                presentHighlightedRunIfNeeded()
                proxy.scrollToContinueHighlight(highlightedRunID ?? highlightedTaskID)
            }
            .onChange(of: highlightedRunSelectionID) { _, _ in
                presentHighlightedRunIfNeeded()
            }
            .onChange(of: highlightedRunID) { _, newValue in
                proxy.scrollToContinueHighlight(newValue ?? highlightedTaskID)
            }
            .onChange(of: highlightedTaskID) { _, newValue in
                proxy.scrollToContinueHighlight(highlightedRunID ?? newValue)
            }
        }
    }

    // MARK: - Active Tasks

    private var activeTasksSection: some View {
        Section {
            let active = store.activeTasks
            if active.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No active tasks.")
                        .foregroundStyle(.secondary)
                    Button {
                        showingAddTask = true
                    } label: {
                        Label("Add a Task", systemImage: "plus.circle")
                    }
                }
            } else {
                ForEach(active) { task in
                    TaskRow(
                        task: task,
                        store: store,
                        isHighlighted: task.id == highlightedTaskID,
                        onSelect: { editingTask = task }
                    )
                    .id(task.id)
                }
            }
        } header: {
            Text("Standalone Tasks")
        }
    }

    // MARK: - Completed Tasks

    @ViewBuilder
    private var completedTasksSection: some View {
        let completed = store.completedTasks
        if !completed.isEmpty {
            Section {
                DisclosureGroup("Completed", isExpanded: $isCompletedTasksExpanded) {
                    ForEach(completed) { task in
                        TaskRow(
                            task: task,
                            store: store,
                            isHighlighted: task.id == highlightedTaskID,
                            onSelect: { editingTask = task }
                        )
                        .id(task.id)
                    }
                }
            }
        }
    }

    // MARK: - Skipped Tasks

    @ViewBuilder
    private var skippedTasksSection: some View {
        let skipped = store.skippedTasks
        if !skipped.isEmpty {
            Section("Skipped") {
                ForEach(skipped) { task in
                    TaskRow(
                        task: task,
                        store: store,
                        isHighlighted: task.id == highlightedTaskID,
                        onSelect: { editingTask = task }
                    )
                    .id(task.id)
                }
            }
        }
    }

    // MARK: - Protocols

    private var protocolsSection: some View {
        Section {
            if store.activeProtocols.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.protocols.isEmpty ? "No household protocols yet." : "No active household protocols.")
                        .foregroundStyle(.secondary)
                    Text(store.protocols.isEmpty ? "Protocols are reusable instruction sets for recurring problems." : "Archived protocols stay available below.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Button {
                        showingAddProtocol = true
                    } label: {
                        Label("Add a Protocol", systemImage: "plus.circle")
                    }
                }
            } else {
                ForEach(store.activeProtocols) { proto in
                    DisclosureGroup {
                        ForEach(Array(proto.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20, alignment: .trailing)
                                Text(step)
                                    .font(.subheadline)
                            }
                        }
                        if !proto.steps.isEmpty {
                            protocolRunActions(for: proto)
                        }
                    } label: {
                        protocolLabel(for: proto)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            store.archiveProtocol(id: proto.id)
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(OwloryColor.textTertiary)
                        Button(role: .destructive) {
                            store.deleteProtocol(id: proto.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            editingProtocol = proto
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(OwloryColor.brandPrimary)
                    }
                }
            }
        } header: {
            Text("Protocols")
        }
    }

    @ViewBuilder
    private var archivedProtocolsSection: some View {
        let archived = store.archivedProtocols
        if !archived.isEmpty {
            Section {
                DisclosureGroup("Archived Protocols", isExpanded: $isArchivedProtocolsExpanded) {
                    ForEach(archived) { proto in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "archivebox")
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(proto.title)
                                    .foregroundStyle(.secondary)
                                Text("Archived")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Button {
                                store.unarchiveProtocol(id: proto.id)
                            } label: {
                                Text("Restore")
                            }
                            .buttonStyle(.borderless)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                store.unarchiveProtocol(id: proto.id)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(OwloryColor.brandPrimary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func protocolLabel(for proto: HouseholdProtocol) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "list.clipboard")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(proto.title)
                if let summary = store.scheduleSummary(for: proto) {
                    Text(
                        HomeProtocolSchedulePresentationFormatting.summaryText(
                            for: summary,
                            calendar: .current
                        )
                    )
                        .font(.caption)
                        .foregroundStyle(summary.status == .overdue ? .orange : .secondary)
                }
            }
        }
    }

    // MARK: - Active Runs

    @ViewBuilder
    private var activeRunsSection: some View {
        let active = store.activeRuns
        if !active.isEmpty {
            Section {
                ForEach(active) { run in
                    Button { activeRunID = run.id } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(run.protocolTitle)
                                    .font(.subheadline.weight(.medium))
                                Text(activeRunSubtitle(for: run))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            ProgressView(value: Double(run.resolvedStepCount), total: Double(run.totalStepCount))
                                .frame(width: 60)
                        }
                    }
                    .buttonStyle(.plain)
                    .continueHighlight(run.id == highlightedRunID)
                    .accessibilityIdentifier("home.protocolRun.item.\(run.id.uuidString)")
                    .id(run.id)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.abandonRun(id: run.id)
                        } label: {
                            Label("Abandon", systemImage: "xmark.circle")
                        }
                    }
            }
        } header: {
            Label("Protocol Runs", systemImage: "play.circle")
        }
    }
    }

    // MARK: - Completed Runs

    @ViewBuilder
    private var completedRunsSection: some View {
        let finished = store.terminalRuns
        if !finished.isEmpty {
            Section {
                DisclosureGroup("Recent Runs", isExpanded: $isRecentRunsExpanded) {
                    ForEach(finished.prefix(5)) { run in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(run.protocolTitle)
                                    .font(.subheadline)
                                HStack(spacing: 4) {
                                    Image(systemName: run.status == .completed ? "checkmark.circle.fill" : "xmark.circle")
                                        .font(.caption2)
                                        .foregroundStyle(run.status == .completed ? OwloryColor.success : OwloryColor.textTertiary)
                                    Text("\(run.completedStepCount)/\(run.totalStepCount) completed")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if let date = run.completedAt {
                                Text(shortDate(date))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    private func activeRunSubtitle(for run: ProtocolRun) -> String {
        let stepText: String
        if let stepNumber = run.nextPendingStepNumber {
            stepText = "Step \(stepNumber) of \(run.totalStepCount)"
        } else {
            stepText = "All steps resolved"
        }
        return "\(stepText) - \(runStartedText(for: run))"
    }

    private func runStartedText(for run: ProtocolRun) -> String {
        let dayCount = run.startedDayCount(asOf: Date())
        switch dayCount {
        case 0:
            return "Started today"
        case 1:
            return "Started yesterday"
        default:
            return "Started \(dayCount) days ago"
        }
    }

    @ViewBuilder
    private func protocolRunActions(for proto: HouseholdProtocol) -> some View {
        if let activeRun = store.activeRun(forProtocolID: proto.id) {
            Button {
                activeRunID = activeRun.id
            } label: {
                Label("Continue Run", systemImage: "play.circle")
                    .font(.subheadline)
                    .foregroundStyle(OwloryColor.brandPrimary)
            }

            Button {
                if let runID = store.startRun(protocolID: proto.id) {
                    activeRunID = runID
                }
            } label: {
                Label("Start New Run", systemImage: "plus.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            Button {
                if let runID = store.continueOrStartRun(protocolID: proto.id) {
                    activeRunID = runID
                }
            } label: {
                Label("Run Protocol", systemImage: "play.circle")
                    .font(.subheadline)
                    .foregroundStyle(OwloryColor.brandPrimary)
            }
        }
    }

    private func presentHighlightedRunIfNeeded() {
        guard let runID = HomeContinueRouting.highlightedRunToPresent(
            highlightedRunID: highlightedRunID,
            requestID: highlightedRunSelectionID,
            lastPresentedRequestID: lastPresentedHighlightedRunSelectionID,
            activeRunIDs: Set(store.activeRuns.map(\.id))
        ) else {
            return
        }

        lastPresentedHighlightedRunSelectionID = highlightedRunSelectionID
        activeRunID = runID
    }

}

// MARK: - Task Row

private struct TaskRow: View {
    let task: HomeTask
    @ObservedObject var store: HomeStore
    let isHighlighted: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if task.isSkipped {
                    store.restoreTask(id: task.id)
                } else {
                    store.toggleComplete(id: task.id)
                }
            } label: {
                Image(systemName: leadingIconName)
                    .foregroundStyle(leadingIconColor)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(leadingButtonAccessibilityLabel)

            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted || task.isSkipped ? .secondary : .primary)
                    HStack(spacing: 8) {
                        if task.isRecurring {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.trianglehead.2.counterclockwise")
                                    .font(.caption2)
                                if let days = task.recurrenceIntervalDays {
                                    Text(RecurrenceIntervalPresentation.compactBadge(days: days))
                                        .font(.caption2)
                                }
                            }
                            .foregroundStyle(OwloryColor.brandPrimary)
                        }
                        if !task.notes.isEmpty {
                            Text(task.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        if task.isSkipped {
                            Label("Skipped", systemImage: "forward.fill")
                                .font(.caption2)
                                .foregroundStyle(OwloryColor.textTertiary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityLabel(HomeAccessibilityLabels.taskEdit(title: task.title))
            .accessibilityHint("Opens task details.")
            .accessibilityIdentifier("home.task.item.\(task.id.uuidString)")

            if let audioFile = task.audioFileName {
                AudioPlaybackButton(fileName: audioFile)
            }

            if !task.isCompleted && !task.isSkipped {
                Button {
                    store.skipTask(id: task.id)
                } label: {
                    Image(systemName: "forward.circle")
                        .foregroundStyle(OwloryColor.textTertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(HomeAccessibilityLabels.taskSkip(title: task.title))
            }
        }
        .continueHighlight(isHighlighted)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.deleteTask(id: task.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var leadingIconName: String {
        if task.isCompleted {
            return "checkmark.circle.fill"
        }
        if task.isSkipped {
            return "forward.circle.fill"
        }
        return "circle"
    }

    private var leadingIconColor: Color {
        if task.isCompleted {
            return OwloryColor.success
        }
        return OwloryColor.textTertiary
    }

    private var leadingButtonAccessibilityLabel: String {
        if task.isCompleted {
            return HomeAccessibilityLabels.taskMarkIncomplete(title: task.title)
        }
        if task.isSkipped {
            return HomeAccessibilityLabels.taskRestore(title: task.title)
        }
        return HomeAccessibilityLabels.taskMarkComplete(title: task.title)
    }
}

// MARK: - Add Task Sheet

private struct AddTaskSheet: View {
    @ObservedObject var store: HomeStore
    let onDismiss: () -> Void
    @State private var title = ""
    @State private var notes = ""
    @State private var isRecurring = false
    @State private var recurrenceDays = 7
    @State private var audioFileName: String?
    @State private var audioTranscription: String?
    @State private var captureRecordID = UUID()

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Task title", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section {
                    Toggle("Recurring", isOn: $isRecurring)
                    if isRecurring {
                        Stepper(value: $recurrenceDays, in: 1...365) {
                            Text(RecurrenceIntervalPresentation.longLabel(days: recurrenceDays))
                        }
                    }
                }
                Section("Voice Recording") {
                    VoiceCaptureButton(recordID: captureRecordID) { text, fileName in
                        audioFileName = fileName
                        audioTranscription = text
                        notes = VoiceTranscriptionRoutingRules.apply(
                            text,
                            to: notes,
                            in: .homeTask
                        )
                    }
                    if let audioFile = audioFileName {
                        HStack {
                            AudioPlaybackButton(fileName: audioFile)
                            Spacer()
                            Text("Recording saved")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let transcription = audioTranscription, !transcription.isEmpty {
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
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addTask(
                            title: title,
                            isRecurring: isRecurring,
                            recurrenceIntervalDays: isRecurring ? recurrenceDays : nil,
                            notes: notes,
                            audioFileName: audioFileName,
                            audioTranscription: audioTranscription
                        )
                        onDismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Edit Task Sheet

private struct EditTaskSheet: View {
    let task: HomeTask
    @ObservedObject var store: HomeStore
    let sourceNoteRoute: HomeTaskSourceRoute
    let onViewSourceNote: (UUID) -> Void
    let onDismiss: () -> Void
    @State private var title: String
    @State private var notes: String
    @State private var isRecurring: Bool
    @State private var recurrenceDays: Int

    init(
        task: HomeTask,
        store: HomeStore,
        sourceNoteRoute: HomeTaskSourceRoute,
        onViewSourceNote: @escaping (UUID) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.task = task
        self.store = store
        self.sourceNoteRoute = sourceNoteRoute
        self.onViewSourceNote = onViewSourceNote
        self.onDismiss = onDismiss
        self._title = State(initialValue: task.title)
        self._notes = State(initialValue: task.notes)
        self._isRecurring = State(initialValue: task.isRecurring)
        self._recurrenceDays = State(initialValue: task.recurrenceIntervalDays ?? 7)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Task title", text: $title)
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                Toggle("Recurring", isOn: $isRecurring)
                if isRecurring {
                    Stepper(value: $recurrenceDays, in: 1...365) {
                        Text(RecurrenceIntervalPresentation.longLabel(days: recurrenceDays))
                    }
                }
                sourceNoteSection
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateTask(
                            id: task.id,
                            title: title,
                            notes: notes,
                            isRecurring: isRecurring,
                            recurrenceIntervalDays: isRecurring ? recurrenceDays : nil
                        )
                        onDismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private var sourceNoteSection: some View {
        switch sourceNoteRoute {
        case .none:
            EmptyView()
        case .availableWritingNote(let noteID):
            Section("Source") {
                Button {
                    onViewSourceNote(noteID)
                } label: {
                    Label("View source note", systemImage: "doc.text")
                }
            }
        case .missingWritingNote:
            Section("Source") {
                Label("Source note unavailable", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Edit Protocol Sheet

private struct EditProtocolSheet: View {
    let proto: HouseholdProtocol
    @ObservedObject var store: HomeStore
    let sourceNoteRoute: HomeProtocolSourceRoute
    let onViewSourceNote: (UUID) -> Void
    let onDismiss: () -> Void
    @State private var title: String
    @State private var stepsText: String
    @State private var scheduleDraft: ProtocolScheduleRules.Draft

    init(
        proto: HouseholdProtocol,
        store: HomeStore,
        sourceNoteRoute: HomeProtocolSourceRoute,
        onViewSourceNote: @escaping (UUID) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.proto = proto
        self.store = store
        self.sourceNoteRoute = sourceNoteRoute
        self.onViewSourceNote = onViewSourceNote
        self.onDismiss = onDismiss
        self._title = State(initialValue: proto.title)
        self._stepsText = State(initialValue: proto.steps.joined(separator: "\n"))
        self._scheduleDraft = State(
            initialValue: ProtocolScheduleRules.Draft(
                schedule: proto.schedule,
                referenceDate: Date()
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Protocol title", text: $title)
                Section("Steps (one per line)") {
                    TextField("Step 1\nStep 2\nStep 3", text: $stepsText, axis: .vertical)
                        .lineLimit(4...10)
                }
                ProtocolScheduleSection(draft: $scheduleDraft)
                sourceNoteSection
                archiveSection
            }
            .navigationTitle("Edit Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let steps = stepsText
                            .components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        store.updateProtocol(
                            id: proto.id,
                            title: title,
                            steps: steps,
                            schedule: ProtocolScheduleRules.schedule(
                                from: scheduleDraft,
                                calendar: .current
                            )
                        )
                        onDismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var sourceNoteSection: some View {
        switch sourceNoteRoute {
        case .none:
            EmptyView()
        case .availableWritingNote(let noteID):
            Section("Source") {
                Button {
                    onViewSourceNote(noteID)
                } label: {
                    Label("View source note", systemImage: "doc.text")
                }
            }
        case .missingWritingNote:
            Section("Source") {
                Label("Source note unavailable", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var archiveSection: some View {
        Section {
            if proto.isArchived {
                Button {
                    store.unarchiveProtocol(id: proto.id)
                    onDismiss()
                } label: {
                    Label("Restore Protocol", systemImage: "arrow.uturn.backward")
                }
            } else {
                Button {
                    store.archiveProtocol(id: proto.id)
                    onDismiss()
                } label: {
                    Label("Archive Protocol", systemImage: "archivebox")
                }
            }
        }
    }
}

// MARK: - Add Protocol Sheet

private struct AddProtocolSheet: View {
    @ObservedObject var store: HomeStore
    let onDismiss: () -> Void
    @State private var title = ""
    @State private var stepsText = ""
    @State private var scheduleDraft = ProtocolScheduleRules.Draft(referenceDate: Date())

    var body: some View {
        NavigationStack {
            Form {
                TextField("Protocol title", text: $title)
                Section("Steps (one per line)") {
                    TextField("Step 1\nStep 2\nStep 3", text: $stepsText, axis: .vertical)
                        .lineLimit(4...10)
                }
                ProtocolScheduleSection(draft: $scheduleDraft)
            }
            .navigationTitle("Add Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let steps = stepsText
                            .components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        store.addProtocol(
                            title: title,
                            steps: steps,
                            schedule: ProtocolScheduleRules.schedule(
                                from: scheduleDraft,
                                calendar: .current
                            )
                        )
                        onDismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct ProtocolScheduleSection: View {
    @Binding var draft: ProtocolScheduleRules.Draft

    var body: some View {
        Section("Schedule") {
            Picker("Window", selection: presetBinding) {
                Text("Anytime").tag(ProtocolSchedulePreset?.none)
                Text("Today").tag(Optional(ProtocolSchedulePreset.today))
                Text("Weekend").tag(Optional(ProtocolSchedulePreset.weekend))
                Text("This Week").tag(Optional(ProtocolSchedulePreset.thisWeek))
                Text("Custom").tag(Optional(ProtocolSchedulePreset.custom))
            }

            if draft.preset == .custom {
                DatePicker("Start", selection: $draft.startDate, displayedComponents: .date)
                DatePicker("End", selection: $draft.endDate, displayedComponents: .date)
            }

            Text(scheduleHelpText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var presetBinding: Binding<ProtocolSchedulePreset?> {
        Binding(
            get: { draft.preset },
            set: { newPreset in
                draft = ProtocolScheduleRules.draft(
                    byApplying: newPreset,
                    to: draft,
                    referenceDate: Date(),
                    calendar: .current
                )
            }
        )
    }

    private var scheduleHelpText: String {
        let summary = ProtocolScheduleRules.summary(
            for: ProtocolScheduleRules.schedule(from: draft, calendar: .current),
            now: Date(),
            calendar: .current
        )

        return HomeProtocolSchedulePresentationFormatting.helpText(
            for: summary,
            calendar: .current
        )
    }
}

private enum HomeProtocolSchedulePresentationFormatting {
    static func summaryText(
        for summary: ProtocolScheduleRules.ScheduleSummary,
        calendar: Calendar
    ) -> String {
        scheduleText(
            preset: summary.preset,
            startDate: summary.startDate,
            endDate: summary.endDate,
            isOverdue: summary.status == .overdue,
            calendar: calendar
        )
    }

    static func helpText(
        for summary: ProtocolScheduleRules.Summary?,
        calendar: Calendar
    ) -> String {
        guard let summary else {
            return NSLocalizedString(
                "home.protocol.schedule.help.anytime",
                comment: "Home protocol schedule help text when no schedule window is selected."
            )
        }

        let label = scheduleText(
            preset: summary.preset,
            startDate: summary.startDate,
            endDate: summary.endDate,
            isOverdue: summary.state == .overdue,
            calendar: calendar
        )

        return String.localizedStringWithFormat(
            NSLocalizedString(
                "home.protocol.schedule.help.scheduled",
                comment: "Home protocol schedule help text with the selected schedule label."
            ),
            label
        )
    }

    private static func scheduleText(
        preset: ProtocolSchedulePreset,
        startDate: Date,
        endDate: Date,
        isOverdue: Bool,
        calendar: Calendar
    ) -> String {
        switch preset {
        case .today:
            return NSLocalizedString(
                isOverdue
                    ? "home.protocol.schedule.today.passed"
                    : "home.protocol.schedule.today",
                comment: "Home protocol schedule label for a today window."
            )
        case .weekend:
            return NSLocalizedString(
                isOverdue
                    ? "home.protocol.schedule.weekend.passed"
                    : "home.protocol.schedule.weekend",
                comment: "Home protocol schedule label for a weekend window."
            )
        case .thisWeek:
            return NSLocalizedString(
                isOverdue
                    ? "home.protocol.schedule.thisWeek.passed"
                    : "home.protocol.schedule.thisWeek",
                comment: "Home protocol schedule label for a this-week window."
            )
        case .custom:
            let key = isOverdue
                ? "home.protocol.schedule.custom.passed"
                : "home.protocol.schedule.custom"
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    key,
                    comment: "Home protocol schedule label for a custom date window."
                ),
                rangeLabel(start: startDate, end: endDate, calendar: calendar)
            )
        }
    }

    private static func rangeLabel(start: Date, end: Date, calendar: Calendar) -> String {
        if calendar.startOfDay(for: start) == calendar.startOfDay(for: end) {
            return dayLabel(start, calendar: calendar)
        }

        return "\(dayLabel(start, calendar: calendar)) - \(dayLabel(end, calendar: calendar))"
    }

    private static func dayLabel(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = calendar.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Protocol Run Sheet

private struct ProtocolRunSheet: View {
    let run: ProtocolRun
    @ObservedObject var store: HomeStore
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Progress")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("home.protocolRun.sheet.\(run.id.uuidString)")
                        Spacer()
                    Text("\(currentRun.resolvedStepCount) of \(currentRun.totalStepCount)")
                        .font(.subheadline.weight(.medium))
                }
                    ProgressView(value: Double(currentRun.resolvedStepCount), total: Double(currentRun.totalStepCount))
                }

                Section {
                    ForEach(currentRun.steps) { step in
                        HStack(spacing: 12) {
                            if step.status == .pending {
                                Button {
                                    store.completeStep(runID: run.id, stepID: step.id)
                                } label: {
                                    stepStatusIcon(step.status)
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(HomeAccessibilityLabels.protocolStepComplete(title: step.title))
                            } else {
                                stepStatusIcon(step.status)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.title)
                                    .font(.subheadline)
                                    .strikethrough(step.status == .completed)
                                    .foregroundStyle(step.status == .pending ? .primary : .secondary)
                                if !step.note.isEmpty {
                                    Text(step.note)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            Spacer()

                            if step.status == .pending {
                                Button {
                                    store.skipStep(runID: run.id, stepID: step.id)
                                } label: {
                                    Image(systemName: "forward.circle")
                                        .foregroundStyle(OwloryColor.textTertiary)
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(HomeAccessibilityLabels.protocolStepSkip(title: step.title))
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            if step.status != .pending {
                                Button {
                                    store.revertStep(runID: run.id, stepID: step.id)
                                } label: {
                                    Label("Mark Pending", systemImage: "arrow.uturn.backward.circle")
                                }
                            }
                        }
                    }
                } header: {
                    Text("Steps")
                }

                if currentRun.status == .active {
                    Section {
                        Button(role: .destructive) {
                            store.abandonRun(id: run.id)
                            onDismiss()
                        } label: {
                            Label("Abandon Run", systemImage: "xmark.circle")
                        }
                    }
                }
            }
            .navigationTitle(run.protocolTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var currentRun: ProtocolRun {
        store.runs.first(where: { $0.id == run.id }) ?? run
    }

    @ViewBuilder
    private func stepStatusIcon(_ status: ProtocolStepStatus) -> some View {
        switch status {
        case .pending:
            Image(systemName: "circle")
                .foregroundStyle(OwloryColor.textTertiary)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(OwloryColor.success)
        case .skipped:
            Image(systemName: "forward.circle.fill")
                .foregroundStyle(OwloryColor.textTertiary)
        }
    }
}
