import SwiftUI

struct CareerView: View {
    @ObservedObject var store: CareerStore
    var highlightedRecordID: UUID?
    @State private var selectedType: CareerRecordType = .win
    @State private var showingAdd = false
    @State private var selectedRecord: CareerRecord?

    var body: some View {
        ScrollViewReader { proxy in
            List {
                typePicker
                recordsList
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Career")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add career record")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddRecordSheet(store: store, recordType: selectedType, onDismiss: { showingAdd = false })
            }
            .sheet(item: $selectedRecord) { record in
                EditRecordSheet(record: record, store: store, onDismiss: { selectedRecord = nil })
            }
            .alert("Couldn't Update Career", isPresented: Binding(
                get: { store.lastError != nil },
                set: { if !$0 { store.lastError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.lastError ?? "")
            }
            .onAppear {
                syncSelectedTypeWithHighlightedRecord()
                proxy.scrollToContinueHighlight(highlightedRecordID)
            }
            .onChange(of: highlightedRecordID) { _, newValue in
                syncSelectedTypeWithHighlightedRecord()
                proxy.scrollToContinueHighlight(newValue)
            }
        }
    }

    private var typePicker: some View {
        Section {
            Picker("Type", selection: $selectedType) {
                ForEach(CareerRecordType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .padding(.horizontal)
        }
    }

    private var recordsList: some View {
        Section {
            let filtered = store.records(ofType: selectedType)
            if filtered.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No \(selectedType.title.lowercased()) records yet.")
                        .foregroundStyle(.secondary)
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Add \(selectedType.title)", systemImage: "plus.circle")
                    }
                }
            } else {
                ForEach(filtered) { record in
                    Button {
                        selectedRecord = record
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(record.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if record.audioFileName != nil {
                                    Image(systemName: "waveform")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Text(recordDateString(record.date))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if !record.body.isEmpty {
                                Text(record.body)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            if !record.metrics.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "chart.bar")
                                        .font(.caption2)
                                    Text(record.metrics)
                                        .font(.caption)
                                }
                                .foregroundStyle(OwloryColor.brandSecondary)
                            }
                        }
                        .continueHighlight(record.id == highlightedRecordID)
                    }
                    .id(record.id)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.deleteRecord(id: record.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        } header: {
            Text("\(selectedType.title) Log")
        }
    }

    private func recordDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func syncSelectedTypeWithHighlightedRecord() {
        guard let highlightedRecordID,
              let record = store.records.first(where: { $0.id == highlightedRecordID }) else {
            return
        }
        selectedType = record.type
    }
}

// MARK: - Add Record

private struct AddRecordSheet: View {
    @ObservedObject var store: CareerStore
    let recordType: CareerRecordType
    let onDismiss: () -> Void
    @State private var title = ""
    @State private var details = ""
    @State private var metrics = ""
    @State private var audioFileName: String?
    @State private var audioTranscription: String?
    @State private var recordID = UUID()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Details", text: $details, axis: .vertical)
                    .lineLimit(3...6)
                TextField("Metrics (optional)", text: $metrics)
                Section("Voice Recording") {
                    VoiceCaptureButton(recordID: recordID) { text, fileName in
                        audioFileName = fileName
                        audioTranscription = text
                        details = VoiceTranscriptionRoutingRules.apply(
                            text,
                            to: details,
                            in: .careerRecord
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
            .navigationTitle("Add \(recordType.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addRecord(
                            type: recordType,
                            title: title,
                            body: details,
                            metrics: metrics,
                            audioFileName: audioFileName,
                            audioTranscription: audioTranscription
                        )
                        onDismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Record

private struct EditRecordSheet: View {
    let record: CareerRecord
    @ObservedObject var store: CareerStore
    let onDismiss: () -> Void
    @State private var title: String
    @State private var details: String
    @State private var metrics: String

    init(record: CareerRecord, store: CareerStore, onDismiss: @escaping () -> Void) {
        self.record = record
        self.store = store
        self.onDismiss = onDismiss
        self._title = State(initialValue: record.title)
        self._details = State(initialValue: record.body)
        self._metrics = State(initialValue: record.metrics)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Details", text: $details, axis: .vertical)
                    .lineLimit(3...6)
                TextField("Metrics", text: $metrics)
                if let audioFile = record.audioFileName {
                    Section("Voice Recording") {
                        HStack {
                            Text("Recording")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            AudioPlaybackButton(fileName: audioFile)
                        }
                        if let transcription = record.audioTranscription, !transcription.isEmpty {
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
            }
            .navigationTitle("Edit \(record.type.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateRecord(id: record.id, title: title, body: details, metrics: metrics)
                        onDismiss()
                    }
                }
            }
        }
    }
}
