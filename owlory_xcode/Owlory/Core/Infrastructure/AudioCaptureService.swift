import AVFoundation
import Speech
#if canImport(Combine)
import Combine
#endif

@MainActor
final class AudioCaptureService: OwloryObservableObject {
    enum State: Equatable {
        case idle
        case recording
        case transcribing
        case finished(text: String, fileName: String)
        case error(String)
    }

    #if canImport(Combine)
    @Published private(set) var state: State = .idle
    @Published private(set) var liveTranscription = ""
    #else
    private(set) var state: State = .idle
    private(set) var liveTranscription = ""
    #endif

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var currentFileURL: URL?
    private var currentFileName: String?
    private let transcriptionService: any SpeechTranscriptionService

    init(transcriptionService: any SpeechTranscriptionService = OnDeviceSpeechTranscriptionService()) {
        self.transcriptionService = transcriptionService
    }

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        let micGranted = await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
        guard micGranted else {
            state = .error("Microphone access denied.")
            return false
        }

        let speechStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else {
            state = .error("Speech recognition not authorized.")
            return false
        }
        return true
    }

    // MARK: - Recording

    func startRecording(for recordID: UUID) throws {
        PerformanceTelemetry.notice(
            "voiceCapture.start record=\(recordID.uuidString)",
            category: .voice
        )
        stopLiveCapture()
        liveTranscription = ""

        let dir = AudioFileStore.audioDirectory()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileName = "\(recordID.uuidString).caf"
        let fileURL = dir.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try session.setActive(true)

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let recordingFile = try AVAudioFile(forWriting: fileURL, settings: inputFormat.settings)
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true

        recognitionRequest = request
        startLiveRecognition(with: request)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, _ in
            request.append(buffer)
            try? recordingFile.write(from: buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            request.endAudio()
            recognitionRequest = nil
            recognitionTask?.cancel()
            recognitionTask = nil
            throw error
        }

        audioEngine = engine
        audioFile = recordingFile
        currentFileURL = fileURL
        currentFileName = fileName
        state = .recording
    }

    func stopRecordingAndTranscribe() async {
        PerformanceTelemetry.notice("voiceCapture.stop", category: .voice)
        stopLiveCapture()
        state = .transcribing

        guard let fileURL = currentFileURL, let fileName = currentFileName else {
            state = .error("No recording file found.")
            return
        }

        let text = await transcriptionService.transcribe(fileURL: fileURL)
        state = .finished(
            text: usableTranscription(preferredText: text),
            fileName: fileName
        )
    }

    func reset() {
        stopLiveCapture()
        state = .idle
        liveTranscription = ""
        currentFileURL = nil
        currentFileName = nil
    }

    func deleteAudioFile(named fileName: String) {
        AudioFileStore.deleteAudioFile(named: fileName)
    }

    func audioFileURL(named fileName: String) -> URL {
        AudioFileStore.audioFileURL(named: fileName)
    }

    private func startLiveRecognition(with request: SFSpeechAudioBufferRecognitionRequest) {
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else { return }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, _ in
            guard let result else { return }
            let text = result.bestTranscription.formattedString
            Task { @MainActor [weak self] in
                self?.liveTranscription = text
            }
        }
    }

    private func stopLiveCapture() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.finish()
        recognitionTask = nil
    }

    private func usableTranscription(preferredText: String) -> String {
        let trimmedPreferred = preferredText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPreferred.isEmpty {
            return trimmedPreferred
        }
        return liveTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
