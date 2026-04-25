import SwiftUI

struct VoiceCaptureButton: View {
    let recordID: UUID
    private let onResult: (VoiceCaptureResult) -> Void

    @StateObject private var service = AudioCaptureService()

    init(
        recordID: UUID,
        onCapture: @escaping (_ transcribedText: String, _ audioFileName: String) -> Void
    ) {
        self.recordID = recordID
        self.onResult = { result in
            onCapture(result.transcribedText, result.audioFileName)
        }
    }

    init(
        recordID: UUID,
        onResult: @escaping (VoiceCaptureResult) -> Void
    ) {
        self.recordID = recordID
        self.onResult = onResult
    }

    var body: some View {
        Button {
            handleTap()
        } label: {
            label
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var label: some View {
        switch service.state {
        case .idle:
            Image(systemName: "mic.circle")
                .font(.title2)
                .foregroundStyle(OwloryColor.brandPrimary)
        case .recording:
            Image(systemName: "stop.circle.fill")
                .font(.title2)
                .foregroundStyle(OwloryColor.error)
        case .transcribing:
            ProgressView()
        case .finished, .error:
            Image(systemName: "mic.circle")
                .font(.title2)
                .foregroundStyle(OwloryColor.brandPrimary)
        }
    }

    private var accessibilityText: String {
        switch service.state {
        case .idle: return "Start voice capture"
        case .recording: return "Stop recording"
        case .transcribing: return "Transcribing"
        case .finished: return "Voice capture complete"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    private func handleTap() {
        Task {
            switch service.state {
            case .idle:
                let granted = await service.requestPermissions()
                guard granted else { return }
                try? service.startRecording(for: recordID)
            case .recording:
                await service.stopRecordingAndTranscribe()
                if case .finished(let text, let fileName) = service.state {
                    onResult(VoiceCaptureResult(transcribedText: text, audioFileName: fileName))
                    service.reset()
                }
            default:
                break
            }
        }
    }
}
