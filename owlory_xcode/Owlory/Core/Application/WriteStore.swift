import Foundation
#if canImport(Combine)
import Combine
#endif

enum WriteContinueRouting {
    static func highlightedNoteToPresent(
        highlightedNoteID: UUID?,
        requestID: UUID?,
        lastPresentedRequestID: UUID?,
        availableNoteIDs: Set<UUID>
    ) -> UUID? {
        guard let highlightedNoteID,
              let requestID,
              requestID != lastPresentedRequestID,
              availableNoteIDs.contains(highlightedNoteID) else {
            return nil
        }

        return highlightedNoteID
    }
}

@MainActor
final class WriteStore: OwloryObservableObject {
    #if canImport(Combine)
    @Published private(set) var notes: [WritingNote] = []
    @Published var lastError: String?
    #else
    private(set) var notes: [WritingNote] = []
    var lastError: String?
    #endif

    private let repository: any ItemListRepository<WritingNote>

    init(
        repository: any ItemListRepository<WritingNote>
    ) {
        self.repository = repository
        load()
    }

    func load() {
        notes = (try? repository.loadAll()) ?? []
    }

    @discardableResult
    func addNote(title: String, body: String, audioFileName: String? = nil, audioTranscription: String? = nil) -> UUID {
        let note = WritingNote(title: title, body: body, audioFileName: audioFileName, audioTranscription: audioTranscription)
        notes.append(note)
        persist()
        return note.id
    }

    func updateNote(id: UUID, title: String, body: String) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].title = title
        notes[index].body = body
        persist()
    }

    func advanceStage(id: UUID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        guard let advanced = try? WritingStageRules.advance(notes[index]) else { return }
        notes[index] = advanced
        persist()
    }

    func transitionStage(id: UUID, to stage: WritingStage) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        guard let transitioned = try? WritingStageRules.transition(notes[index], to: stage) else { return }
        notes[index] = transitioned
        persist()
    }

    @discardableResult
    func turnIntoSourceNote(id: UUID, metadata: WritingSourceMetadata) -> Bool {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return false }

        var updated = notes[index]
        updated.sourceMetadata = metadata

        if updated.stage != .source {
            guard let transitioned = try? WritingStageRules.transition(updated, to: .source) else {
                lastError = "This note can't be turned into a source note from its current stage."
                return false
            }
            updated = transitioned
        }

        notes[index] = updated
        persist()
        return true
    }

    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        persist()
    }

    var notesByStage: [WritingStage: [WritingNote]] {
        Dictionary(grouping: notes, by: \.stage)
    }

    private func persist() {
        do {
            try repository.saveAll(notes)
            lastError = nil
        } catch {
            lastError = String(localized: "write.error.note.save")
        }
    }
}
