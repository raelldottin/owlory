import AVFoundation
import SwiftUI

struct AudioPlaybackButton: View {
    let fileName: String

    @StateObject private var player = AudioPlayerService()

    var body: some View {
        Button {
            handleTap()
        } label: {
            label
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
        .onDisappear {
            player.stop()
        }
    }

    @ViewBuilder
    private var label: some View {
        switch player.state {
        case .idle:
            Image(systemName: "play.circle")
                .font(.title3)
                .foregroundStyle(OwloryColor.brandSecondary)
        case .playing:
            Image(systemName: "stop.circle.fill")
                .font(.title3)
                .foregroundStyle(OwloryColor.brandPrimary)
        case .error:
            Image(systemName: "exclamationmark.circle")
                .font(.title3)
                .foregroundStyle(OwloryColor.error)
        }
    }

    private var accessibilityText: String {
        switch player.state {
        case .idle: return "Play recording"
        case .playing: return "Stop playback"
        case .error(let msg): return "Playback error: \(msg)"
        }
    }

    private func handleTap() {
        switch player.state {
        case .idle, .error:
            let url = AudioFileStore.audioFileURL(named: fileName)
            player.play(url: url)
        case .playing:
            player.stop()
        }
    }
}

// MARK: - Audio Player Service

@MainActor
private final class AudioPlayerService: OwloryObservableObject, @unchecked Sendable {
    enum State: Equatable {
        case idle
        case playing
        case error(String)
    }

    #if canImport(Combine)
    @Published private(set) var state: State = .idle
    #else
    private(set) var state: State = .idle
    #endif

    private var audioPlayer: AVAudioPlayer?
    private var delegate: PlayerDelegate?

    func play(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            state = .error("Recording not found.")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            delegate = PlayerDelegate { [weak self] in
                self?.state = .idle
            }
            audioPlayer?.delegate = delegate
            audioPlayer?.play()
            state = .playing
        } catch {
            state = .error("Could not play recording.")
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        delegate = nil
        state = .idle
    }
}

// MARK: - AVAudioPlayerDelegate

private final class PlayerDelegate: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    let onFinish: @MainActor () -> Void

    init(onFinish: @escaping @MainActor () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            onFinish()
        }
    }
}
