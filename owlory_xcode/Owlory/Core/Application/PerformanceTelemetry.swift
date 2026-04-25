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
}
