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
    #else
    private(set) var state: State = .idle
    #endif

    private var audioRecorder: AVAudioRecorder?
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
        let dir = AudioFileStore.audioDirectory()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileName = "\(recordID.uuidString).m4a"
        let fileURL = dir.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default)
        try session.setActive(true)

        audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder?.record()
        currentFileURL = fileURL
        currentFileName = fileName
        state = .recording
    }

    func stopRecordingAndTranscribe() async {
        audioRecorder?.stop()
        state = .transcribing

        guard let fileURL = currentFileURL, let fileName = currentFileName else {
            state = .error("No recording file found.")
            return
        }

        let text = await transcriptionService.transcribe(fileURL: fileURL)
        state = .finished(text: text, fileName: fileName)
    }

    func reset() {
        state = .idle
        currentFileURL = nil
        currentFileName = nil
    }

    func deleteAudioFile(named fileName: String) {
        AudioFileStore.deleteAudioFile(named: fileName)
    }

    func audioFileURL(named fileName: String) -> URL {
        AudioFileStore.audioFileURL(named: fileName)
    }

}
