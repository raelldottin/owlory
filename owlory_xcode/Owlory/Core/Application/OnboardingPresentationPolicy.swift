import Foundation

/// Persistence wrapper for the "user has seen the onboarding tutorial" flag.
///
/// The current onboarding version is bumped when the tour content materially
/// changes so we can re-show the tour to existing users without resetting
/// other defaults.
enum OnboardingCompletion {
    static let currentVersion: Int = 1
    static let storageKey: String = "owlory.onboarding.completedVersion"

    static func isComplete(defaults: UserDefaults = .standard) -> Bool {
        defaults.integer(forKey: storageKey) >= currentVersion
    }

    static func markComplete(defaults: UserDefaults = .standard) {
        defaults.set(currentVersion, forKey: storageKey)
    }
}

/// Decides whether the onboarding tour should appear on the next launch.
///
/// UI testing and marketing-screenshot harnesses must land directly in the
/// dashboard so seeded fixtures and tab navigation tests are not blocked by
/// the tour. For those runs we treat the tour as already complete.
enum OnboardingPresentationPolicy {
    static func shouldShowOnLaunch(
        defaults: UserDefaults = .standard,
        isUITesting: Bool = OwloryUITestSupport.isUITesting
    ) -> Bool {
        if isUITesting { return false }
        return !OnboardingCompletion.isComplete(defaults: defaults)
    }
}
