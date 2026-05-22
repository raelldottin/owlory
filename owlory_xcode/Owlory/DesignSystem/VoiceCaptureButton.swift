import SwiftUI

struct VoiceCaptureButton: View {
    let recordID: UUID
    private let onResult: (VoiceCaptureResult) -> Void
    private let onRecordingStarted: () -> Void
    private let onLiveTranscription: (String) -> Void

    @StateObject private var service = AudioCaptureService()

    init(
        recordID: UUID,
        onRecordingStarted: @escaping () -> Void = {},
        onLiveTranscription: @escaping (_ transcribedText: String) -> Void = { _ in },
        onCapture: @escaping (_ transcribedText: String, _ audioFileName: String) -> Void
    ) {
        self.recordID = recordID
        self.onRecordingStarted = onRecordingStarted
        self.onLiveTranscription = onLiveTranscription
        self.onResult = { result in
            onCapture(result.transcribedText, result.audioFileName)
        }
    }

    init(
        recordID: UUID,
        onRecordingStarted: @escaping () -> Void = {},
        onLiveTranscription: @escaping (_ transcribedText: String) -> Void = { _ in },
        onResult: @escaping (VoiceCaptureResult) -> Void
    ) {
        self.recordID = recordID
        self.onRecordingStarted = onRecordingStarted
        self.onLiveTranscription = onLiveTranscription
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
        .accessibilityInputLabels([LocalizedStringKey("voicecontrol.label.startRecording")])
        .sensoryFeedback(.impact(weight: .medium), trigger: isRecording)
        .onChange(of: service.liveTranscription) { _, text in
            onLiveTranscription(text)
        }
    }

    private var isRecording: Bool {
        if case .recording = service.state { return true }
        return false
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
        case .idle:
            return NSLocalizedString(
                "voice.capture.accessibility.start",
                comment: "Voice capture button accessibility label when idle."
            )
        case .recording:
            return NSLocalizedString(
                "voice.capture.accessibility.stop",
                comment: "Voice capture button accessibility label when recording."
            )
        case .transcribing:
            return NSLocalizedString(
                "voice.capture.accessibility.transcribing",
                comment: "Voice capture button accessibility label while transcription is running."
            )
        case .finished:
            return NSLocalizedString(
                "voice.capture.accessibility.finished",
                comment: "Voice capture button accessibility label after capture completes."
            )
        case .error:
            return NSLocalizedString(
                "voice.capture.accessibility.error",
                comment: "Voice capture button accessibility label after capture failed."
            )
        }
    }

    private func handleTap() {
        Task {
            switch service.state {
            case .idle, .error:
                let granted = await service.requestPermissions()
                guard granted else { return }
                do {
                    try service.startRecording(for: recordID)
                    onRecordingStarted()
                } catch {
                    break
                }
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
