import Foundation

enum ReadinessRules {

    struct Nudge {
        let message: String
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
                message: "Tough signals today. Focus on one thing that matters and let the rest go.",
                suggestedMaxPriorities: 1
            )
        }

        // Two low signals
        if low >= 2 {
            return Nudge(
                message: "Low reserves today. Keep the plan light — minimum viable wins.",
                suggestedMaxPriorities: 2
            )
        }

        // Low energy specifically (common limiter)
        if energy <= 2 {
            return Nudge(
                message: "Low energy today. Favor easy wins over deep work.",
                suggestedMaxPriorities: 2
            )
        }

        // Poor sleep specifically
        if sleepQuality <= 2 {
            return Nudge(
                message: "Sleep was rough. You may have less focus than you think.",
                suggestedMaxPriorities: 2
            )
        }

        // Rough mood
        if mood <= 2 {
            return Nudge(
                message: "Rough mood today. Be honest about what you can carry.",
                suggestedMaxPriorities: 2
            )
        }

        // All signals high
        if high == 3 {
            return Nudge(
                message: "Strong signals today. Good day for deep work or hard problems.",
                suggestedMaxPriorities: 3
            )
        }

        // Two high signals
        if high >= 2 {
            return Nudge(
                message: "Solid day. You have capacity — use it on what matters most.",
                suggestedMaxPriorities: 3
            )
        }

        // Everything moderate
        if avg >= 2.5 && avg <= 3.5 {
            return Nudge(
                message: "Steady day. Trust the plan.",
                suggestedMaxPriorities: 3
            )
        }

        // Slightly above average
        return Nudge(
            message: "Decent day ahead. Stay focused on your priorities.",
            suggestedMaxPriorities: 3
        )
    }
}
