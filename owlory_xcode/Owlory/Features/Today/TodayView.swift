import SwiftUI

struct TodayView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @ObservedObject var store: TodayStore
    @ObservedObject var trainStore: TrainStore
    @ObservedObject var writeStore: WriteStore
    @ObservedObject var careerStore: CareerStore
    @ObservedObject var homeStore: HomeStore
    @ObservedObject var patternStore: PatternStore
    @ObservedObject var completionHistory: CompletionHistoryStore
    var onContinueItemSelected: (TodayContinuationRules.ContinueItem) -> Void = { _ in }

    @State private var reflectionText = ""
    @State private var reflectionSaved = false
    @State private var reflectionAudioFileName: String?
    @State private var showingCheckin = false
    @State private var showingReflection = false

    // Quick-add sheet states
    @State private var showingQuickTrainSession = false
    @State private var showingQuickCapture = false
    @State private var showingQuickCareerRecord = false
    @State private var showingQuickHomeTask = false
    @State private var showingBuildInfo = false

    var body: some View {
        Group {
            switch store.entryState {
            case .missing:
                welcomeView
            case .setupIncomplete, .active, .reflected, .historical:
                dashboardView
            }
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(usesInlineNavigationTitle ? .inline : .automatic)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingBuildInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("Open build info")
                .accessibilityHint("Shows the app version, build number, and git commit for bug reports.")
            }
        }
        .sheet(isPresented: $showingBuildInfo) {
            BuildInfoView(onDismiss: { showingBuildInfo = false })
        }
        .sheet(isPresented: $showingQuickTrainSession) {
            QuickTrainSheet(store: trainStore, onDismiss: { showingQuickTrainSession = false })
        }
        .sheet(isPresented: $showingQuickCapture) {
            QuickCaptureSheet(store: writeStore, onDismiss: { showingQuickCapture = false })
        }
        .sheet(isPresented: $showingQuickCareerRecord) {
            QuickCareerSheet(store: careerStore, onDismiss: { showingQuickCareerRecord = false })
        }
        .sheet(isPresented: $showingQuickHomeTask) {
            QuickHomeTaskSheet(store: homeStore, onDismiss: { showingQuickHomeTask = false })
        }
        .alert("Couldn't Update Today", isPresented: Binding(
            get: { store.lastError != nil },
            set: { if !$0 { store.lastError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.lastError ?? "")
        }
    }

    // MARK: - Welcome

    private var welcomeView: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text(dateString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Good to see you")
                        .font(.title2.weight(.semibold))
                        .accessibilityIdentifier("today.welcome.title")
                    Text("Here's what's active across your life.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("today.welcome.subtitle")
                    Button {
                        store.loadToday()
                    } label: {
                        Text("Start Today")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .accessibilityIdentifier("today.welcome.start")
                }
                .padding(.vertical, 8)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Dashboard

    private var dashboardView: some View {
        List {
            dashboardHeader
            checkInSection
            continueSection
            focusSuggestionSection
            domainTrainCard
            domainWriteCard
            domainCareerCard
            domainHomeCard
            dashboardReflection
            lastWeekSection
            previousDaysSection
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            if case .setupIncomplete = store.entryState {
                store.markSetupComplete()
            }
            store.loadRecentEntries()
            patternStore.refresh()
            refreshFocusSuggestions()
        }
        .onChange(of: focusSuggestionRefreshKey) { _, _ in
            refreshFocusSuggestions()
        }
    }

    // MARK: - Header

    private var dashboardHeader: some View {
        Section {
            if usesCompactHeightAccessibilityLayout {
                compactHeightDashboardHeader
            } else {
                standardDashboardHeader
            }
        }
    }

    private var headerGreeting: String {
        let hasCheckedIn = TodayStore.hasCheckIn(currentEntry)
        if case .reflected = store.entryState {
            return "Day complete"
        }
        if hasCheckedIn {
            return usesAccessibilityCompactHeader ? "In progress" : "Day in progress"
        }
        if usesCompactHeightAccessibilityLayout {
            return "Ready when you are"
        }
        if usesAccessibilityCompactHeader {
            return "Today's plan"
        }
        return "What's active today?"
    }

    private var calibration: CalibrationRules.Calibration {
        CalibrationRules.calibrate(
            todayEntry: currentEntry,
            weeklySnapshot: patternStore.weeklySnapshot
        )
    }

    private var readinessNudge: ReadinessRules.Nudge? {
        calibration.enhancedNudge
    }

    private var eveningReflectionNudge: TodayStore.EveningReflectionNudge? {
        if case .historical = store.entryState {
            return nil
        }

        return TodayStore.eveningReflectionNudge(
            for: currentEntry,
            homeTasks: homeStore.tasks,
            now: Date()
        )
    }

    // MARK: - Check-in

    private var checkInSection: some View {
        Section {
            DisclosureGroup(isExpanded: $showingCheckin) {
                readinessRow(label: "Energy", value: currentEntry.energy, systemImage: "bolt.fill", anchors: ("Low", "Okay", "High")) { val in
                    store.updateReadiness(energy: val, mood: currentEntry.mood, sleepQuality: currentEntry.sleepQuality)
                }
                readinessRow(label: "Mood", value: currentEntry.mood, systemImage: "face.smiling", anchors: ("Rough", "Steady", "Good")) { val in
                    store.updateReadiness(energy: currentEntry.energy, mood: val, sleepQuality: currentEntry.sleepQuality)
                }
                readinessRow(label: "Sleep", value: currentEntry.sleepQuality, systemImage: "moon.zzz", anchors: ("Poor", "Fine", "Great")) { val in
                    store.updateReadiness(energy: currentEntry.energy, mood: currentEntry.mood, sleepQuality: val)
                }
            } label: {
                if usesCompactHeightAccessibilityLayout {
                    compactHeightCheckInLabel
                } else if usesStackedCheckInLabel {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(checkInTitle, systemImage: "heart.text.clipboard")
                            .font(checkInTitleFont)
                        Text(readinessSummaryLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack(spacing: 12) {
                        Label(checkInTitle, systemImage: "heart.text.clipboard")
                            .font(checkInTitleFont)
                        Spacer()
                        Text(readinessSummaryLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
    }

    private var readinessSummaryLabel: String {
        let e = currentEntry.energy
        let m = currentEntry.mood
        let s = currentEntry.sleepQuality
        guard e != 3 || m != 3 || s != 3 else {
            return usesAccessibilityCompactHeader ? "Check in now" : "Tap to check in"
        }
        let avg = Double(e + m + s) / 3.0
        if avg >= 4.0 { return usesAccessibilityCompactHeader ? "Strong today" : "Feeling strong today" }
        if avg <= 2.0 { return usesAccessibilityCompactHeader ? "Low reserves" : "Low reserves today" }
        if usesCompactHeightAccessibilityLayout { return "Mixed readiness" }

        func tag(_ label: String, _ v: Int) -> String {
            switch v {
            case 1...2: return "\(label) low"
            case 3: return "\(label) okay"
            case 4...5: return "\(label) high"
            default: return label
            }
        }
        return "\(tag("Energy", e)) · \(tag("Mood", m)) · \(tag("Sleep", s))"
    }

    // MARK: - Continue

    @ViewBuilder
    private var continueSection: some View {
        let items = continueItems
        if !items.isEmpty {
            Section {
                ForEach(items) { item in
                    Button {
                        onContinueItemSelected(item)
                    } label: {
                        continueRow(for: item)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        continuePrimarySwipeActions(for: item)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        continueStatusSwipeActions(for: item)
                    }
                    .accessibilityHint(continueAccessibilityHint(for: item))
                    .accessibilityIdentifier(continueAccessibilityIdentifier(for: item))
                }
            } header: {
                Text("Continue")
                    .accessibilityIdentifier("today.continue.header")
            } footer: {
                if items.contains(where: { $0.staleDayCount != nil }) {
                    Text("Items with a day badge have been carried for a few days. Focus-backed rows can be swiped to mark done, defer, or drop.")
                } else if items.contains(where: { focusItem(for: $0) != nil }) {
                    Text("Focus lives in Continue. Swipe Focus-backed rows to mark done, defer, or drop.")
                }
            }
        }
    }

    @ViewBuilder
    private func continuePrimarySwipeActions(for item: TodayContinuationRules.ContinueItem) -> some View {
        if let focusItem = focusItem(for: item), focusItem.status != .done {
            Button {
                store.updateStatus(for: focusItem.id, to: .done)
            } label: {
                Label("Done", systemImage: "checkmark.circle")
            }
            .tint(OwloryColor.success)
            .accessibilityIdentifier(continueActionAccessibilityIdentifier("done", for: item))
        } else if store.canAddContinueItemToFocus(item) {
            Button {
                store.addContinueItemToFocus(item)
            } label: {
                Label("Add to Focus", systemImage: "plus.circle")
            }
            .tint(OwloryColor.brandPrimary)
        }
    }

    @ViewBuilder
    private func continueStatusSwipeActions(for item: TodayContinuationRules.ContinueItem) -> some View {
        if let focusItem = focusItem(for: item) {
            if focusItem.status != .deferred {
                Button {
                    store.updateStatus(for: focusItem.id, to: .deferred)
                } label: {
                    Label("Defer", systemImage: "clock.arrow.circlepath")
                }
                .tint(OwloryColor.warning)
                .accessibilityIdentifier(continueActionAccessibilityIdentifier("defer", for: item))
            }

            if focusItem.status != .dropped {
                Button(role: .destructive) {
                    store.updateStatus(for: focusItem.id, to: .dropped)
                } label: {
                    Label("Drop", systemImage: "xmark.circle")
                }
                .accessibilityIdentifier(continueActionAccessibilityIdentifier("drop", for: item))
            }
        }
    }

    private func continueAccessibilityHint(for item: TodayContinuationRules.ContinueItem) -> String {
        if focusItem(for: item) != nil {
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "today.continue.accessibility.focusStatusActions",
                    comment: "Continue row accessibility hint for Focus-backed rows."
                ),
                item.domain.localizedDisplayName
            )
        }
        if store.canAddContinueItemToFocus(item) {
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "today.continue.accessibility.addToFocus",
                    comment: "Continue row accessibility hint for rows that can be added to Focus."
                ),
                item.domain.localizedDisplayName
            )
        }
        return String.localizedStringWithFormat(
            NSLocalizedString(
                "today.continue.accessibility.openDomain",
                comment: "Continue row accessibility hint for opening a domain."
            ),
            item.domain.localizedDisplayName
        )
    }

    private func continueAccessibilityIdentifier(for item: TodayContinuationRules.ContinueItem) -> String {
        let sourceToken = item.source.key.replacingOccurrences(of: "|", with: ".")
        return "today.continue.item.\(sourceToken)"
    }

    private func continueActionAccessibilityIdentifier(
        _ action: String,
        for item: TodayContinuationRules.ContinueItem
    ) -> String {
        let sourceToken = item.source.key.replacingOccurrences(of: "|", with: ".")
        return "today.continue.action.\(action).\(sourceToken)"
    }

    private func continueRow(for item: TodayContinuationRules.ContinueItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: domainIcon(item.domain))
                .font(.subheadline)
                .foregroundStyle(OwloryColor.brandPrimary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                HStack(spacing: 6) {
                    Text(item.domain.localizedDisplayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !item.reason.isEmpty {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(item.reason)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
            if let staleDayCount = item.staleDayCount {
                Text("\(staleDayCount)d")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(OwloryColor.warning)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(OwloryColor.warning.opacity(0.12), in: Capsule())
            }
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }

    private func focusItem(for item: TodayContinuationRules.ContinueItem) -> FocusItem? {
        switch item.source {
        case .focusItem(let itemID), .carriedFocusItem(let itemID):
            return currentEntry.focusThree.first { $0.id == itemID }
        case .homeProtocolRun:
            return nil
        case .trainingSession, .homeTask, .writingNote:
            if let linkedRecordID = item.focusLinkedRecordID,
               let exactMatch = currentEntry.focusThree.first(where: {
                   $0.status == .planned &&
                       $0.domain == item.domain &&
                       $0.linkedRecordID == linkedRecordID
               }) {
                return exactMatch
            }
            return currentEntry.focusThree.first {
                $0.status == .planned &&
                    $0.domain == item.domain &&
                    normalizedFocusTitle($0.title) == normalizedFocusTitle(item.title)
            }
        }
    }

    private func normalizedFocusTitle(_ title: String) -> String {
        title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    @ViewBuilder
    private var focusSuggestionSection: some View {
        let drafts = store.focusSuggestionDrafts
        if !drafts.isEmpty {
            Section {
                ForEach(drafts) { draft in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: domainIcon(draft.domain))
                                .font(.subheadline)
                                .foregroundStyle(OwloryColor.brandPrimary)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(draft.title)
                                    .font(.subheadline)
                                Text(draft.domain.localizedDisplayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        if !draft.reason.isEmpty {
                            Text(draft.reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 12) {
                            Button {
                                store.acceptFocusSuggestion(id: draft.id)
                            } label: {
                                Text("Add")
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                store.dismissFocusSuggestion(id: draft.id)
                            } label: {
                                Text("Dismiss")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            } header: {
                Text("Focus Suggestions")
            } footer: {
                Text("These stay draft-only until you add one.")
            }
        }
    }

    private var continueItems: [TodayContinuationRules.ContinueItem] {
        TodayContinuationRules.derive(
            todayEntry: currentEntry,
            calibration: calibration,
            todaySessions: trainStore.todaySessions,
            homeTasks: homeStore.activeTasks,
            homeRuns: homeStore.runs,
            homeProtocols: homeStore.protocols,
            writingNotes: writeStore.notes,
            predictions: completionHistory.predictions
        )
    }

    // MARK: - Domain Cards (compact summary + quick create)

    private var domainTrainCard: some View {
        Section {
            let todaySessions = trainStore.todaySessions
            let planned = todaySessions.filter { $0.status == .planned }.count
            let completed = todaySessions.filter { $0.status == .completed || $0.status == .modified }.count

            VStack(alignment: .leading, spacing: 2) {
                if todaySessions.isEmpty {
                    Text("No sessions today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(todayTrainSummary(planned: planned, completed: completed))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let next = todaySessions.first(where: { $0.status == .planned }) {
                    Text("Next: \(next.plannedActivity)")
                        .font(.caption)
                        .foregroundStyle(OwloryColor.brandPrimary.opacity(0.8))
                }
            }
            Button {
                showingQuickTrainSession = true
            } label: {
                Label("Add session", systemImage: "plus.circle")
                    .font(.subheadline)
                    .foregroundStyle(OwloryColor.brandPrimary)
            }
        } header: {
            Label("Train", systemImage: "figure.run")
        }
    }

    private var domainWriteCard: some View {
        Section {
            let notesByStage = writeStore.notesByStage
            let captures = notesByStage[.capture]?.count ?? 0
            let sources = notesByStage[.source]?.count ?? 0
            let drafts = (notesByStage[.draftSeed]?.count ?? 0) + (notesByStage[.draft]?.count ?? 0)
            let totalActive = writeStore.notes.filter { $0.stage != .archived }.count

            VStack(alignment: .leading, spacing: 2) {
                if totalActive == 0 {
                    Text("No active notes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(todayWriteSummary(captures: captures, sources: sources, drafts: drafts))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if captures > 0 && sources == 0 {
                        Text("A good next step: develop a source note")
                            .font(.caption)
                            .foregroundStyle(OwloryColor.brandPrimary.opacity(0.8))
                    } else if let latest = writeStore.notes.first(where: { $0.stage != .archived && $0.stage != .published }) {
                        Text("Next: \(latest.title)")
                            .font(.caption)
                            .foregroundStyle(OwloryColor.brandPrimary.opacity(0.8))
                            .lineLimit(1)
                    }
                }
            }
            Button {
                showingQuickCapture = true
            } label: {
                Label("Capture a note", systemImage: "plus.circle")
                    .font(.subheadline)
                    .foregroundStyle(OwloryColor.brandPrimary)
            }
        } header: {
            Label("Write", systemImage: "square.and.pencil")
        }
    }

    private var domainCareerCard: some View {
        Section {
            let count = careerStore.records.count
            VStack(alignment: .leading, spacing: 2) {
                if count == 0 {
                    Text("No records yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Start by saving one concrete win")
                        .font(.caption)
                        .foregroundStyle(OwloryColor.brandPrimary.opacity(0.8))
                } else {
                    Text(todayCareerRecordCount(count))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Button {
                showingQuickCareerRecord = true
            } label: {
                Label("Record a win", systemImage: "plus.circle")
                    .font(.subheadline)
                    .foregroundStyle(OwloryColor.brandPrimary)
            }
        } header: {
            Label("Career", systemImage: "briefcase")
        }
    }

    private var domainHomeCard: some View {
        Section {
            let active = homeStore.activeTasks
            let activeRuns = homeStore.activeRuns
            let completed = homeStore.completedTasks
            let skipped = homeStore.skippedTasks

            VStack(alignment: .leading, spacing: 2) {
                if active.isEmpty && activeRuns.isEmpty && completed.isEmpty && skipped.isEmpty {
                    Text("No home work yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(
                        homeTaskSummary(
                            activeTasks: active.count,
                            activeRuns: activeRuns.count,
                            completed: completed.count,
                            skipped: skipped.count
                        )
                    )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let nextRun = activeRuns.first {
                        Text("Active protocol: \(nextRun.protocolTitle)")
                            .font(.caption)
                            .foregroundStyle(OwloryColor.brandPrimary.opacity(0.8))
                            .lineLimit(1)
                    } else if let next = active.first {
                        Text("Next task: \(next.title)")
                            .font(.caption)
                            .foregroundStyle(OwloryColor.brandPrimary.opacity(0.8))
                            .lineLimit(1)
                    }
                }
            }
            Button {
                showingQuickHomeTask = true
            } label: {
                Label("Add task", systemImage: "plus.circle")
                    .font(.subheadline)
                    .foregroundStyle(OwloryColor.brandPrimary)
            }
        } header: {
            Label("Home", systemImage: "house")
        }
    }

    private func todayTrainSummary(planned: Int, completed: Int) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString(
                "today.dashboard.train.summary",
                comment: "Today Train card summary with planned and completed session counts."
            ),
            planned,
            completed
        )
    }

    private func todayWriteSummary(captures: Int, sources: Int, drafts: Int) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString(
                "today.dashboard.write.summary",
                comment: "Today Write card summary with capture, source, and draft note counts."
            ),
            captures,
            sources,
            drafts
        )
    }

    private func todayCareerRecordCount(_ count: Int) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString(
                "today.dashboard.career.records",
                comment: "Today Career card summary with career record count."
            ),
            count
        )
    }

    private func homeTaskSummary(
        activeTasks: Int,
        activeRuns: Int,
        completed: Int,
        skipped: Int
    ) -> String {
        if skipped > 0 {
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "today.dashboard.home.summary.withSkipped",
                    comment: "Today Home card summary with protocol run, task, done, and skipped counts."
                ),
                activeRuns,
                activeTasks,
                completed,
                skipped
            )
        }
        return String.localizedStringWithFormat(
            NSLocalizedString(
                "today.dashboard.home.summary",
                comment: "Today Home card summary with protocol run, task, and done counts."
            ),
            activeRuns,
            activeTasks,
            completed
        )
    }

    // MARK: - Evening Reflection

    private var dashboardReflection: some View {
        Section {
            DisclosureGroup(isExpanded: $showingReflection) {
                HStack(alignment: .top) {
                    TextField("What mattered today?", text: $reflectionText, axis: .vertical)
                        .lineLimit(3...6)
                    VoiceCaptureButton(recordID: currentEntry.id) { text, fileName in
                        reflectionText = VoiceTranscriptionRoutingRules.apply(
                            text,
                            to: reflectionText,
                            in: .todayReflection
                        )
                        reflectionAudioFileName = fileName
                    }
                }
                .onChange(of: reflectionText) { _ in
                    if reflectionSaved { reflectionSaved = false }
                }
                if reflectionSaved {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(OwloryColor.success)
                            .font(.subheadline)
                        Text("Saved")
                            .font(.subheadline)
                            .foregroundStyle(OwloryColor.success)
                        Spacer()
                        if let audioFile = reflectionAudioFileName ?? currentEntry.reflectionAudioFileName {
                            AudioPlaybackButton(fileName: audioFile)
                        }
                    }
                    .transition(.opacity)
                } else {
                    Button {
                        store.saveReflection(reflectionText, audioFileName: reflectionAudioFileName)
                        withAnimation { reflectionSaved = true }
                    } label: {
                        Text("Save Reflection")
                    }
                    .disabled(reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("Evening Reflection", systemImage: "moon.stars")
                            .font(.subheadline.weight(.medium))
                        if !reflectionSaved && currentEntry.eveningReflection.isEmpty {
                            Text("Close the day with one quick note")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer()
                    if reflectionSaved || !currentEntry.eveningReflection.isEmpty {
                        Text("Done")
                            .font(.caption)
                            .foregroundStyle(OwloryColor.success)
                    }
                }
            }
        }
        .onAppear {
            let existing = currentEntry.eveningReflection
            if !existing.isEmpty {
                reflectionText = existing
                reflectionSaved = true
                showingReflection = false
            }
        }
    }

    // MARK: - Last Week Digest

    @ViewBuilder
    private var lastWeekSection: some View {
        if let digest = patternStore.latestDigest {
            Section {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            digestStat(
                                label: "Days active",
                                value: WeeklyDigestPresentationFormatting.daysActiveValue(digest.daysWithEntries)
                            )
                            Spacer()
                            digestStat(
                                label: "Completed",
                                value: WeeklyDigestPresentationFormatting.completionRatioValue(
                                    done: digest.totalDone,
                                    planned: digest.totalPlanned
                                )
                            )
                            Spacer()
                            digestStat(
                                label: "Streak",
                                value: WeeklyDigestPresentationFormatting.compactStreakDaysValue(digest.streakDays)
                            )
                        }

                        if digest.averageReadiness > 0 {
                            HStack {
                                Text("Avg readiness")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(WeeklyDigestPresentationFormatting.averageReadinessValue(digest.averageReadiness))
                                    .font(.caption.weight(.medium))
                            }
                        }

                        if let best = digest.bestDay {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(OwloryColor.success)
                                Text(best.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let hardest = digest.hardestDay {
                            HStack(spacing: 4) {
                                Image(systemName: "cloud.rain")
                                    .font(.caption2)
                                    .foregroundStyle(OwloryColor.warning)
                                Text(hardest.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !digest.keyInsight.isEmpty {
                            Text(digest.keyInsight)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .italic()
                                .padding(.top, 4)
                        }

                        NavigationLink {
                            DigestListView(
                                patternStore: patternStore,
                                calendar: patternStore.weeklyDigestCalendar
                            )
                        } label: {
                            Text("View all digests")
                                .font(.caption)
                                .foregroundStyle(OwloryColor.brandPrimary)
                        }
                        .padding(.top, 4)
                    }
                } label: {
                    HStack {
                        Label(
                            WeeklyDigestPresentationFormatting.relativeWeekLabel(
                                for: digest,
                                now: Date(),
                                calendar: patternStore.weeklyDigestCalendar
                            ),
                            systemImage: "calendar.badge.clock"
                        )
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(WeeklyDigestPresentationFormatting.collapsedCompletionSummary(for: digest))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var previousDaysSection: some View {
        if !store.recentEntries.isEmpty {
            Section {
                NavigationLink {
                    PreviousDaysView(
                        entries: store.recentEntries,
                        statusResolver: makeLiveStatusResolver()
                    )
                } label: {
                    HStack {
                        Label("Browse Previous Days", systemImage: "clock.arrow.circlepath")
                            .font(.subheadline)
                        Spacer()
                        Text("\(store.recentEntries.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("History")
            } footer: {
                Text("Review what you planned, what carried forward, and what still connects to current work.")
            }
        }
    }

    private func makeLiveStatusResolver() -> (OwloryItemOrigin) -> PreviousDayLiveStatus? {
        let sessions = trainStore.sessions
        let tasks = homeStore.tasks
        let runs = homeStore.runs
        let protocols = homeStore.protocols
        let notes = writeStore.notes

        return { origin in
            switch origin.kind {
            case .trainingSession:
                guard let session = sessions.first(where: { $0.id == origin.id }) else { return nil }
                switch session.status {
                case .planned: return .active
                case .completed: return .completed
                case .modified: return .completed
                case .skipped: return .skipped
                }
            case .homeTask:
                guard let task = tasks.first(where: { $0.id == origin.id }) else { return nil }
                if task.isCompleted { return .completed }
                if task.isSkipped { return .skipped }
                return .active
            case .homeProtocolRun:
                guard let run = runs.first(where: { $0.id == origin.id }) else { return nil }
                switch run.status {
                case .active:
                    let proto = protocols.first { $0.id == run.protocolID }
                    if proto?.isArchived == true { return .archived }
                    return .active
                case .completed: return .completed
                case .abandoned: return .abandoned
                }
            case .writingNote:
                guard let note = notes.first(where: { $0.id == origin.id }) else { return nil }
                if note.stage == .archived { return .archived }
                return .active
            case .careerRecord:
                return nil
            }
        }
    }

    private func digestStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Shared Components

    private func readinessRow(
        label: String,
        value: Int,
        systemImage: String,
        anchors: (String, String, String),
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                Label(label, systemImage: systemImage)
                    .font(.subheadline)
                    .frame(width: 90, alignment: .leading)
                ForEach(1...5, id: \.self) { level in
                    Button {
                        onChange(level)
                    } label: {
                        Circle()
                            .fill(level <= value ? readinessColor(for: value) : OwloryColor.borderSubtle)
                            .frame(width: level == value ? 18 : 14, height: level == value ? 18 : 14)
                            .animation(.easeInOut(duration: 0.15), value: value)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(
                        readinessScaleAccessibilityLabel(
                            label: label,
                            level: level,
                            isSelected: level == value
                        )
                    )
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

    private func readinessScaleAccessibilityLabel(label: String, level: Int, isSelected: Bool) -> String {
        let key = isSelected
            ? "today.readiness.scale.accessibility.selected"
            : "today.readiness.scale.accessibility"
        return String.localizedStringWithFormat(
            NSLocalizedString(
                key,
                comment: "Today readiness scale accessibility label with dimension name and level."
            ),
            NSLocalizedString(label, comment: "Today readiness dimension label."),
            level
        )
    }

    private func readinessColor(for value: Int) -> Color {
        switch value {
        case 1...2: return OwloryColor.error
        case 3: return OwloryColor.warning
        case 4...5: return OwloryColor.success
        default: return OwloryColor.textTertiary
        }
    }

    private func domainIcon(_ domain: LifeDomain) -> String {
        switch domain {
        case .training: return "figure.run"
        case .writing: return "square.and.pencil"
        case .career: return "briefcase"
        case .home: return "house"
        }
    }

    // MARK: - Helpers

    private var currentEntry: DailyEntry {
        switch store.entryState {
        case .setupIncomplete(let entry), .active(let entry), .reflected(let entry), .historical(let entry):
            return entry
        case .missing:
            return DailyEntry(date: .now)
        }
    }

    private var usesCompactHeaderDate: Bool {
        dynamicTypeSize.isAccessibilitySize || verticalSizeClass == .compact
    }

    private var usesAccessibilityCompactHeader: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var usesCompactHeightAccessibilityLayout: Bool {
        dynamicTypeSize.isAccessibilitySize && verticalSizeClass == .compact
    }

    private var usesInlineNavigationTitle: Bool {
        dynamicTypeSize.isAccessibilitySize || verticalSizeClass == .compact
    }

    private var usesStackedCheckInLabel: Bool {
        dynamicTypeSize >= .xxxLarge || dynamicTypeSize.isAccessibilitySize
    }

    private var checkInTitle: String {
        usesAccessibilityCompactHeader ? "Check in" : "Check-in"
    }

    private var checkInTitleFont: Font {
        if usesCompactHeightAccessibilityLayout {
            return Font.footnote.weight(.semibold)
        }
        return usesAccessibilityCompactHeader ? Font.footnote.weight(.semibold) : Font.subheadline.weight(.medium)
    }

    private var dashboardHeaderSpacing: CGFloat {
        usesCompactHeightAccessibilityLayout ? 4 : (dynamicTypeSize.isAccessibilitySize ? 6 : 8)
    }

    private var headerDateString: String {
        currentEntry.date.formatted(usesCompactHeaderDate ? compactHeaderDateFormat : fullHeaderDateFormat)
    }

    private var headerDateFont: Font {
        if usesCompactHeightAccessibilityLayout {
            return Font.caption2
        }
        return dynamicTypeSize.isAccessibilitySize ? Font.footnote : Font.subheadline
    }

    private var headerGreetingFont: Font {
        if usesCompactHeightAccessibilityLayout {
            return Font.callout.weight(.semibold)
        }
        return dynamicTypeSize.isAccessibilitySize ? Font.headline.weight(.semibold) : Font.title3.weight(.semibold)
    }

    private var headerSupportingFont: Font {
        if usesCompactHeightAccessibilityLayout {
            return Font.caption
        }
        return dynamicTypeSize.isAccessibilitySize ? Font.footnote : Font.subheadline
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: currentEntry.date)
    }

    private var fullHeaderDateFormat: Date.FormatStyle {
        .dateTime.weekday(.wide).month(.wide).day().year()
    }

    private var compactHeaderDateFormat: Date.FormatStyle {
        usesAccessibilityCompactHeader
            ? .dateTime.weekday(.abbreviated).month(.abbreviated).day()
            : .dateTime.weekday(.abbreviated).month(.abbreviated).day().year()
    }

    private var standardDashboardHeader: some View {
        VStack(alignment: .leading, spacing: dashboardHeaderSpacing) {
            Text(headerDateString)
                .font(headerDateFont)
                .foregroundStyle(.secondary)
            Text(headerGreeting)
                .font(headerGreetingFont)
                .accessibilityIdentifier("today.dashboard.header")
            if let nudge = readinessNudge {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkle")
                        .font(.caption)
                        .foregroundStyle(OwloryColor.brandPrimary)
                    Text(nudge.message)
                        .font(headerSupportingFont)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
            if let domainNudge = calibration.domainNudge {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "eye")
                        .font(.caption)
                        .foregroundStyle(OwloryColor.warning)
                    Text(domainNudge.message)
                        .font(headerSupportingFont)
                        .foregroundStyle(.secondary)
                }
            }
            if let reflectionNudge = eveningReflectionNudge {
                Button {
                    withAnimation {
                        showingReflection = true
                    }
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "moon.stars")
                            .font(.caption)
                            .foregroundStyle(OwloryColor.brandPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reflectionNudge.title)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text(reflectionNudge.message)
                                .font(headerSupportingFont)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var compactHeightDashboardHeader: some View {
        VStack(alignment: .leading, spacing: dashboardHeaderSpacing) {
            Text(headerDateString)
                .font(headerDateFont)
                .foregroundStyle(.secondary)
            Text(readinessNudge?.message ?? headerGreeting)
                .font(headerGreetingFont)
                .accessibilityIdentifier("today.dashboard.header")
            if let domainNudge = calibration.domainNudge {
                Text(domainNudge.message)
                    .font(headerSupportingFont)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var compactHeightCheckInLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(checkInTitle)
                .font(checkInTitleFont)
            Text(readinessSummaryLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var focusSuggestionCandidates: [TodayStore.FocusSuggestionCandidate] {
        TodayStore.makeFocusSuggestionCandidates(
            todayEntry: currentEntry,
            recentEntries: store.recentEntries,
            predictions: completionHistory.predictions,
            now: Date(),
            activeItems: focusSuggestionActiveItems
        )
    }

    private var focusSuggestionActiveItems: [TodayStore.FocusSuggestionActiveItem] {
        continueItems.map { item in
            TodayStore.FocusSuggestionActiveItem(title: item.title, domain: item.domain)
        }
    }

    private var focusSuggestionRefreshKey: String {
        let entrySignature = currentEntry.focusThree
            .map { "\($0.id.uuidString):\($0.status.rawValue):\($0.title)" }
            .joined(separator: ",")
        let candidateSignature = focusSuggestionCandidates
            .map { "\($0.priority):\($0.domain.rawValue):\($0.title):\($0.reason)" }
            .joined(separator: ",")
        let snapshotStamp = patternStore.weeklySnapshot?.generatedAt.timeIntervalSinceReferenceDate ?? 0
        return [
            currentEntry.id.uuidString,
            entrySignature,
            String(calibration.suggestedFocusLoad),
            String(snapshotStamp),
            candidateSignature
        ].joined(separator: "|")
    }

    private func refreshFocusSuggestions() {
        if case .missing = store.entryState {
            return
        }
        store.refreshFocusSuggestions(
            todayEntry: currentEntry,
            weeklySnapshot: patternStore.weeklySnapshot,
            candidates: focusSuggestionCandidates
        )
    }
}

// MARK: - Previous Days

private struct PreviousDaysView: View {
    let entries: [DailyEntry]
    let statusResolver: (OwloryItemOrigin) -> PreviousDayLiveStatus?

    var body: some View {
        List {
            ForEach(entries) { entry in
                NavigationLink {
                    PreviousDayDetailView(entry: entry, statusResolver: statusResolver)
                } label: {
                    PreviousDayRow(entry: entry)
                }
            }
        }
        .navigationTitle("Previous Days")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PreviousDayRow: View {
    let entry: DailyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dateLabel)
                .font(.subheadline.weight(.medium))
            HStack(spacing: 12) {
                Label("\(entry.focusThree.count)", systemImage: "checklist")
                if entry.energy > 0 || entry.mood > 0 || entry.sleepQuality > 0 {
                    Label(readinessLabel, systemImage: "heart.text.clipboard")
                }
                if !entry.eveningReflection.isEmpty {
                    Label("Reflected", systemImage: "moon.stars")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if let firstFocus = entry.focusThree.first {
                Text(firstFocus.title)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: entry.date)
    }

    private var readinessLabel: String {
        let average = Double(entry.energy + entry.mood + entry.sleepQuality) / 3.0
        return String(format: "%.1f / 5", average)
    }
}

enum PreviousDayLiveStatus {
    case active
    case completed
    case skipped
    case archived
    case abandoned

    var localizedDisplayName: String {
        switch self {
        case .active:
            return String(localized: "display.previousDayLiveStatus.active")
        case .completed:
            return String(localized: "display.previousDayLiveStatus.completed")
        case .skipped:
            return String(localized: "display.previousDayLiveStatus.skipped")
        case .archived:
            return String(localized: "display.previousDayLiveStatus.archived")
        case .abandoned:
            return String(localized: "display.previousDayLiveStatus.abandoned")
        }
    }

    var color: Color {
        switch self {
        case .active: return OwloryColor.brandPrimary
        case .completed: return OwloryColor.success
        case .skipped, .archived, .abandoned: return OwloryColor.textTertiary
        }
    }
}

private extension LifeDomain {
    var localizedDisplayName: String {
        switch self {
        case .training:
            return String(localized: "display.lifeDomain.training")
        case .writing:
            return String(localized: "display.lifeDomain.writing")
        case .career:
            return String(localized: "display.lifeDomain.career")
        case .home:
            return String(localized: "display.lifeDomain.home")
        }
    }
}

private extension FocusItemStatus {
    var localizedDisplayName: String {
        switch self {
        case .planned:
            return String(localized: "display.focusItemStatus.planned")
        case .done:
            return String(localized: "display.focusItemStatus.done")
        case .deferred:
            return String(localized: "display.focusItemStatus.deferred")
        case .dropped:
            return String(localized: "display.focusItemStatus.dropped")
        }
    }
}

private extension CareerRecordType {
    var localizedDisplayName: String {
        switch self {
        case .win:
            return String(localized: "display.careerRecordType.win")
        case .impact:
            return String(localized: "display.careerRecordType.impact")
        case .story:
            return String(localized: "display.careerRecordType.story")
        }
    }
}

private struct PreviousDayDetailView: View {
    let entry: DailyEntry
    let statusResolver: (OwloryItemOrigin) -> PreviousDayLiveStatus?

    var body: some View {
        List {
            overviewSection
            focusSection
            intentionsSection
            carryForwardSection
            reflectionSection
        }
        .navigationTitle(dateLabel)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var overviewSection: some View {
        Section("Overview") {
            if entry.energy > 0 || entry.mood > 0 || entry.sleepQuality > 0 {
                LabeledContent("Energy", value: "\(entry.energy)/5")
                LabeledContent("Mood", value: "\(entry.mood)/5")
                LabeledContent("Sleep", value: "\(entry.sleepQuality)/5")
            } else {
                Text("No check-in recorded.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var focusSection: some View {
        if !entry.focusThree.isEmpty {
            Section("Focus") {
                ForEach(entry.focusThree) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline.weight(.medium))
                        HStack(spacing: 8) {
                            Text(item.domain.localizedDisplayName)
                            Text(item.status.localizedDisplayName)
                            if let status = resolveStatus(for: item) {
                                Text(status.localizedDisplayName)
                                    .foregroundStyle(status.color)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var intentionsSection: some View {
        let intentions = entry.domainIntentions
            .filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { $0.key.rawValue < $1.key.rawValue }
        if !intentions.isEmpty {
            Section("Domain Intentions") {
                ForEach(intentions, id: \.key) { domain, text in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(domain.localizedDisplayName)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text(text)
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var carryForwardSection: some View {
        if !entry.carryForward.isEmpty {
            Section("Carry Forward") {
                ForEach(entry.carryForward) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(item.title)
                                .font(.subheadline)
                            if let status = resolveStatus(for: item) {
                                Spacer()
                                Text(status.localizedDisplayName)
                                    .font(.caption)
                                    .foregroundStyle(status.color)
                            }
                        }
                        Text(item.domain.localizedDisplayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var reflectionSection: some View {
        if !entry.eveningReflection.isEmpty {
            Section("Reflection") {
                Text(entry.eveningReflection)
                    .font(.subheadline)
            }
        }
    }

    private func resolveStatus(for item: FocusItem) -> PreviousDayLiveStatus? {
        guard let origin = item.origin else { return nil }
        return statusResolver(origin)
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: entry.date)
    }
}

// MARK: - Quick-Add Sheets

private struct QuickTrainSheet: View {
    @ObservedObject var store: TrainStore
    let onDismiss: () -> Void
    @State private var activity = ""
    @State private var readinessLevel = 3
    @State private var isRecurring = false
    @State private var recurrenceDays = 1

    var body: some View {
        NavigationStack {
            Form {
                TextField("What's the session?", text: $activity)
                Section("Readiness") {
                    TrainingReadinessScaleRow(
                        label: "Training",
                        value: readinessLevel,
                        anchors: ("Low", "Okay", "High")
                    ) { value in
                        readinessLevel = value
                    }
                }
                Toggle("Repeat this session", isOn: $isRecurring)
                if isRecurring {
                    Stepper(value: $recurrenceDays, in: 1...365) {
                        Text(RecurrenceIntervalPresentation.longLabel(days: recurrenceDays))
                    }
                }
            }
            .navigationTitle("Plan Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addSession(
                            plannedActivity: activity,
                            readinessLevel: readinessLevel,
                            isRecurring: isRecurring,
                            recurrenceIntervalDays: isRecurring ? recurrenceDays : nil
                        )
                        onDismiss()
                    }
                    .disabled(activity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct QuickCaptureSheet: View {
    @ObservedObject var store: WriteStore
    let onDismiss: () -> Void
    @State private var title = ""
    @State private var body_ = ""
    @State private var audioFileName: String?
    @State private var titleCaptureID = UUID()
    @State private var bodyCaptureID = UUID()

    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    TextField("Title", text: $title)
                    VoiceCaptureButton(recordID: titleCaptureID) { text, _ in
                        title = VoiceTranscriptionRoutingRules.apply(
                            text,
                            to: title,
                            in: .todayQuickNote,
                            requestedField: .title
                        )
                    }
                }
                HStack(alignment: .top) {
                    TextField("Body (optional)", text: $body_, axis: .vertical)
                        .lineLimit(3...6)
                    VoiceCaptureButton(recordID: bodyCaptureID) { text, fileName in
                        body_ = VoiceTranscriptionRoutingRules.apply(
                            text,
                            to: body_,
                            in: .todayQuickNote,
                            requestedField: .body
                        )
                        audioFileName = fileName
                    }
                }
            }
            .navigationTitle("Capture Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addNote(title: title, body: body_, audioFileName: audioFileName)
                        onDismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct QuickCareerSheet: View {
    @ObservedObject var store: CareerStore
    let onDismiss: () -> Void
    @State private var title = ""
    @State private var details = ""
    @State private var recordType: CareerRecordType = .win
    @State private var audioFileName: String?
    @State private var titleCaptureID = UUID()
    @State private var detailsCaptureID = UUID()

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $recordType) {
                    ForEach(CareerRecordType.allCases) { type in
                        Text(type.localizedDisplayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                HStack {
                    TextField("Title", text: $title)
                    VoiceCaptureButton(recordID: titleCaptureID) { text, _ in
                        title = VoiceTranscriptionRoutingRules.apply(
                            text,
                            to: title,
                            in: .todayQuickCareer,
                            requestedField: .title
                        )
                    }
                }
                HStack(alignment: .top) {
                    TextField("Details (optional)", text: $details, axis: .vertical)
                        .lineLimit(2...4)
                    VoiceCaptureButton(recordID: detailsCaptureID) { text, fileName in
                        details = VoiceTranscriptionRoutingRules.apply(
                            text,
                            to: details,
                            in: .todayQuickCareer,
                            requestedField: .details
                        )
                        audioFileName = fileName
                    }
                }
            }
            .navigationTitle(
                String.localizedStringWithFormat(
                    NSLocalizedString(
                        "today.quickCareer.recordTitle",
                        comment: "Navigation title for recording a career item from Today."
                    ),
                    recordType.localizedDisplayName
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addRecord(type: recordType, title: title, body: details, audioFileName: audioFileName)
                        onDismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct QuickHomeTaskSheet: View {
    @ObservedObject var store: HomeStore
    let onDismiss: () -> Void
    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Task title", text: $title)
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addTask(title: title)
                        onDismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
