import Foundation

#if canImport(OSLog)
    import OSLog
#endif

enum OwloryTelemetryCategory: String {
    case appLifecycle = "app.lifecycle"
    case continueFlow = "today.continue"
    case patterns
    case persistence
    case performance
    case recurrence = "recurrence.rollover"
    case reminders = "reminder.schedule"
    /// Voice capture start/stop boundaries — answers "why did this recording
    /// take so long?" when a user reports a slow capture.
    case voice
    /// Wraps the on-device speech transcription call — answers "is
    /// transcription slow on a specific device?" when comparing devices.
    case transcription = "speech.transcription"
    /// Wraps the protocol run completion path — answers "did the user's run
    /// complete take >1s after tap?" for tap-to-update latency.
    case homeProtocol = "home.protocolRun"
}

enum PerformanceTelemetry {
    static let subsystem = "com.raelldottin.owlory"

    #if canImport(OSLog)
        static func logger(_ category: OwloryTelemetryCategory) -> Logger {
            Logger(subsystem: subsystem, category: category.rawValue)
        }
    #endif

    static func notice(_ message: String, category: OwloryTelemetryCategory) {
        #if canImport(OSLog)
            logger(category).notice("\(message, privacy: .public)")
        #endif
    }

    static func measure<T>(
        _ name: StaticString,
        category: OwloryTelemetryCategory,
        operation: () throws -> T
    ) rethrows -> T {
        #if canImport(OSLog)
            let signposter = OSSignposter(logger: logger(category))
            let state = signposter.beginInterval(name)
            defer {
                signposter.endInterval(name, state)
            }
        #endif

        return try operation()
    }

    /// Async-aware variant of `measure` for awaitable work. The signpost
    /// interval covers the full `await`, so transcription and other async
    /// adapters show up in Instruments as a single timed span.
    static func measureAsync<T>(
        _ name: StaticString,
        category: OwloryTelemetryCategory,
        operation: () async throws -> T
    ) async rethrows -> T {
        #if canImport(OSLog)
            let signposter = OSSignposter(logger: logger(category))
            let state = signposter.beginInterval(name)
            defer {
                signposter.endInterval(name, state)
            }
        #endif

        return try await operation()
    }
}
