import Foundation

struct VoiceCaptureResult: Equatable {
    let transcribedText: String
    let audioFileName: String

    var hasTranscription: Bool {
        !transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
