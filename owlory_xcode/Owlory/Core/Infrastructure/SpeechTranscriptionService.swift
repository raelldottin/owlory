import AVFoundation
import Foundation
import Speech

protocol SpeechTranscriptionService {
    func transcribe(fileURL: URL) async -> String
}

struct OnDeviceSpeechTranscriptionService: SpeechTranscriptionService {
    func transcribe(fileURL: URL) async -> String {
        await PerformanceTelemetry.measureAsync(
            "speechTranscription.run",
            category: .transcription
        ) {
            #if !os(watchOS)
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, *) {
                if let transcript = await transcribeWithSpeechAnalyzer(fileURL: fileURL), !transcript.isEmpty {
                    return transcript
                }
            }
            #endif

            return await transcribeWithLegacyRecognizer(fileURL: fileURL)
        }
    }

    #if !os(watchOS)
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, *)
    private func transcribeWithSpeechAnalyzer(fileURL: URL) async -> String? {
        guard SpeechTranscriber.isAvailable else {
            return nil
        }

        do {
            let locale = await SpeechTranscriber.supportedLocale(equivalentTo: .current) ?? .current
            let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
            let analyzer = SpeechAnalyzer(
                modules: [transcriber],
                options: .init(priority: .userInitiated, modelRetention: .whileInUse)
            )
            let audioFile = try AVAudioFile(forReading: fileURL)

            async let transcription = transcriber.results.reduce("") { partial, result in
                partial + String(result.text.characters)
            }

            if let lastSample = try await analyzer.analyzeSequence(from: audioFile) {
                try await analyzer.finalizeAndFinish(through: lastSample)
            } else {
                await analyzer.cancelAndFinishNow()
            }

            return try await transcription
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
    #endif

    private func transcribeWithLegacyRecognizer(fileURL: URL) async -> String {
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            return ""
        }

        let request = SFSpeechURLRecognitionRequest(url: fileURL)
        request.requiresOnDeviceRecognition = true

        do {
            return try await withCheckedThrowingContinuation { continuation in
                let resolver = SpeechRecognitionContinuation(continuation)
                recognizer.recognitionTask(with: request) { result, error in
                    if error != nil {
                        resolver.resume(with: "")
                        return
                    }
                    if let result, result.isFinal {
                        resolver.resume(with: result.bestTranscription.formattedString)
                    }
                }
            }
        } catch {
            return ""
        }
    }
}

private final class SpeechRecognitionContinuation {
    private let lock = NSLock()
    private var didResume = false
    private let continuation: CheckedContinuation<String, any Error>

    init(_ continuation: CheckedContinuation<String, any Error>) {
        self.continuation = continuation
    }

    func resume(with value: String) {
        lock.lock()
        defer { lock.unlock() }
        guard !didResume else { return }
        didResume = true
        continuation.resume(returning: value)
    }
}
