import Foundation

enum ReadinessSummaryPresentation {
    struct CheckInLayout {
        var usesCompactHeader: Bool
        var prefersMixedShortcut: Bool
    }

    static func todayCheckInLabel(
        energy: Int,
        mood: Int,
        sleep: Int,
        layout: CheckInLayout
    ) -> String {
        guard energy != 3 || mood != 3 || sleep != 3 else {
            return localized(
                layout.usesCompactHeader
                    ? "readiness.checkin.summary.tap.compact"
                    : "readiness.checkin.summary.tap"
            )
        }

        let average = Double(energy + mood + sleep) / 3.0
        if average >= 4.0 {
            return localized(
                layout.usesCompactHeader
                    ? "readiness.checkin.summary.strong.compact"
                    : "readiness.checkin.summary.strong"
            )
        }
        if average <= 2.0 {
            return localized(
                layout.usesCompactHeader
                    ? "readiness.checkin.summary.low.compact"
                    : "readiness.checkin.summary.low"
            )
        }
        if layout.prefersMixedShortcut {
            return localized("readiness.checkin.summary.mixed")
        }
        return [
            axisTier(localized("Energy"), value: energy),
            axisTier(localized("Mood"), value: mood),
            axisTier(localized("Sleep"), value: sleep)
        ].joined(separator: " · ")
    }

    private static func axisTier(_ name: String, value: Int) -> String {
        let key: String
        switch value {
        case 1...2: key = "readiness.axis.tier.low"
        case 3: key = "readiness.axis.tier.okay"
        case 4...5: key = "readiness.axis.tier.high"
        default: return name
        }
        return String.localizedStringWithFormat(
            NSLocalizedString(
                key,
                comment: "Readiness per-axis tier label such as Energy low / Mood okay / Sleep high."
            ),
            name
        )
    }

    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}
