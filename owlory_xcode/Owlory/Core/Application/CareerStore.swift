import Foundation
#if canImport(Combine)
import Combine
#endif

@MainActor
final class CareerStore: OwloryObservableObject {
    #if canImport(Combine)
    @Published private(set) var records: [CareerRecord] = []
    @Published var lastError: String?
    #else
    private(set) var records: [CareerRecord] = []
    var lastError: String?
    #endif

    private let repository: any ItemListRepository<CareerRecord>

    init(
        repository: any ItemListRepository<CareerRecord>
    ) {
        self.repository = repository
        load()
    }

    func load() {
        records = (try? repository.loadAll()) ?? []
    }

    @discardableResult
    func addRecord(type: CareerRecordType, title: String, body: String = "", metrics: String = "", audioFileName: String? = nil, audioTranscription: String? = nil) -> UUID {
        let record = CareerRecord(type: type, title: title, body: body, metrics: metrics, audioFileName: audioFileName, audioTranscription: audioTranscription)
        records.append(record)
        persist()
        return record.id
    }

    func updateRecord(id: UUID, title: String, body: String, metrics: String) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].title = title
        records[index].body = body
        records[index].metrics = metrics
        persist()
    }

    func deleteRecord(id: UUID) {
        records.removeAll { $0.id == id }
        persist()
    }

    func records(ofType type: CareerRecordType) -> [CareerRecord] {
        records
            .filter { $0.type == type }
            .sorted { $0.date > $1.date }
    }

    private func persist() {
        do {
            try repository.saveAll(records)
            lastError = nil
        } catch {
            lastError = String(localized: "career.error.record.save")
        }
    }
}
