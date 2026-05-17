import Foundation

enum ReadinessRules {

    struct Nudge: Equatable {
        enum Kind: Equatable {
            case toughSignals
            case lowReserves
            case lowEnergy
            case sleepWasRough
            case roughMood
            case strongSignals
            case solidDay
            case steadyDay
            case decentDay
        }

        let kind: Kind
        let suggestedMaxPriorities: Int
    }

    /// Returns an adaptive nudge based on today's readiness signals.
    /// Energy, mood, and sleepQuality are each 1–5.
    /// Returns nil when all values are at default (0) — no check-in yet.
    static func nudge(energy: Int, mood: Int, sleepQuality: Int) -> Nudge? {
        guard energy > 0 || mood > 0 || sleepQuality > 0 else { return nil }

        let avg = Double(energy + mood + sleepQuality) / 3.0
        let low = [energy, mood, sleepQuality].filter { $0 <= 2 }.count
        let high = [energy, mood, sleepQuality].filter { $0 >= 4 }.count

        // All signals low
        if low == 3 {
            return Nudge(
                kind: .toughSignals,
                suggestedMaxPriorities: 1
            )
        }

        // Two low signals
        if low >= 2 {
            return Nudge(
                kind: .lowReserves,
                suggestedMaxPriorities: 2
            )
        }

        // Low energy specifically (common limiter)
        if energy <= 2 {
            return Nudge(
                kind: .lowEnergy,
                suggestedMaxPriorities: 2
            )
        }

        // Poor sleep specifically
        if sleepQuality <= 2 {
            return Nudge(
                kind: .sleepWasRough,
                suggestedMaxPriorities: 2
            )
        }

        // Rough mood
        if mood <= 2 {
            return Nudge(
                kind: .roughMood,
                suggestedMaxPriorities: 2
            )
        }

        // All signals high
        if high == 3 {
            return Nudge(
                kind: .strongSignals,
                suggestedMaxPriorities: 3
            )
        }

        // Two high signals
        if high >= 2 {
            return Nudge(
                kind: .solidDay,
                suggestedMaxPriorities: 3
            )
        }

        // Everything moderate
        if avg >= 2.5 && avg <= 3.5 {
            return Nudge(
                kind: .steadyDay,
                suggestedMaxPriorities: 3
            )
        }

        // Slightly above average
        return Nudge(
            kind: .decentDay,
            suggestedMaxPriorities: 3
        )
    }
}
