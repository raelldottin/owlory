import SwiftUI

/// First-launch tutorial that walks the user through every tab of Owlory.
///
/// Presented full-screen on top of `RootTabView` while
/// `OnboardingCompletion.isOnboardingComplete` is `false`. Each page explains
/// one surface, in the same order the tab bar renders them, so the user can
/// step through, swipe back, or skip ahead and reach the dashboard with a
/// mental model of where each kind of work lives.
struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onComplete: () -> Void

    @State private var pageIndex: Int = 0

    private var pages: [OnboardingPage] { OnboardingPage.allPages }

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $pageIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                        .padding(.horizontal, 24)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .animation(OwloryMotion.animation(.easeInOut(duration: 0.25), reduce: reduceMotion), value: pageIndex)

            pageIndicator

            footer
        }
        .background(OwloryColor.backgroundPrimary.ignoresSafeArea())
        .accessibilityIdentifier("onboarding.root")
    }

    private var header: some View {
        HStack {
            Spacer()
            if !isLastPage {
                Button(action: completeOnboarding) {
                    Text(L("Skip"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(OwloryColor.textSecondary)
                }
                .accessibilityIdentifier("onboarding.skip")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .frame(height: 44)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Circle()
                    .fill(index == pageIndex ? OwloryColor.brandPrimary : OwloryColor.borderSubtle)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Page \(pageIndex + 1) of \(pages.count)"))
    }

    private var footer: some View {
        HStack {
            backButton
            Spacer()
            primaryButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private var backButton: some View {
        if pageIndex > 0 {
            Button {
                advance(by: -1)
            } label: {
                Text(L("Back"))
                    .font(.body.weight(.medium))
                    .foregroundStyle(OwloryColor.brandPrimary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
            }
            .accessibilityIdentifier("onboarding.back")
        } else {
            Color.clear.frame(width: 1, height: 1)
        }
    }

    private var primaryButton: some View {
        Button {
            if isLastPage {
                completeOnboarding()
            } else {
                advance(by: 1)
            }
        } label: {
            Text(L(isLastPage ? "Get Started" : "Next"))
                .font(.body.weight(.semibold))
                .foregroundStyle(OwloryColor.brandOnPrimary)
                .padding(.vertical, 14)
                .padding(.horizontal, 28)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .fill(OwloryColor.brandPrimary)
                )
        }
        .accessibilityIdentifier(isLastPage ? "onboarding.finish" : "onboarding.next")
    }

    private var isLastPage: Bool {
        pageIndex >= pages.count - 1
    }

    private func advance(by step: Int) {
        let target = min(max(pageIndex + step, 0), pages.count - 1)
        OwloryMotion.withAnimation(.easeInOut(duration: 0.25), reduce: reduceMotion) {
            pageIndex = target
        }
    }

    private func completeOnboarding() {
        onComplete()
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 8)

            iconBadge

            VStack(spacing: 12) {
                Text(L(page.title))
                    .font(.largeTitle.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(OwloryColor.textPrimary)

                Text(L(page.subtitle))
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(OwloryColor.textSecondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(page.bullets.enumerated()), id: \.offset) { _, bullet in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(OwloryColor.brandPrimary)
                            .accessibilityHidden(true)
                        Text(L(bullet))
                            .font(.body)
                            .foregroundStyle(OwloryColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .fill(OwloryColor.surfaceElevated)
            )

            Spacer(minLength: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("onboarding.page.\(page.identifier)")
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(OwloryColor.brandPrimary.opacity(0.12))
                .frame(width: 112, height: 112)
            Image(systemName: page.systemImage)
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(OwloryColor.brandPrimary)
        }
        .accessibilityHidden(true)
    }
}

private struct OnboardingPage {
    let identifier: String
    let title: String
    let subtitle: String
    let systemImage: String
    let bullets: [String]

    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            identifier: "welcome",
            title: "Welcome to Owlory",
            subtitle: "Your private, local-first command center for everyday life.",
            systemImage: "sparkles",
            bullets: [
                "Owlory keeps daily planning, training, writing, career, and home in one place.",
                "Everything stays on your device. There is no account and no sync.",
                "This quick tour explains what each tab is for so you know where to start."
            ]
        ),
        OnboardingPage(
            identifier: "today",
            title: "Today",
            subtitle: "Your daily command center.",
            systemImage: "sun.max",
            bullets: [
                "Check in with energy, mood, and sleep, then pick up to three focus items for the day.",
                "Continue picks up unfinished work from every other tab so nothing slips silently.",
                "End the day with an evening reflection that feeds your weekly digest."
            ]
        ),
        OnboardingPage(
            identifier: "train",
            title: "Train",
            subtitle: "One training session a day, tracked honestly.",
            systemImage: "figure.run",
            bullets: [
                "Plan today's session, log your readiness, and capture what you actually did.",
                "Recurring sessions roll forward automatically when the day changes.",
                "Reflections can be typed or dictated and stay attached to each session."
            ]
        ),
        OnboardingPage(
            identifier: "write",
            title: "Write",
            subtitle: "A low-friction inbox for unfinished thought.",
            systemImage: "square.and.pencil",
            bullets: [
                "Capture an idea fast — no folder, tag, or category required.",
                "Promote captures into source notes, tasks, or protocols later, only when it helps.",
                "Write is forgiving: catch the thought first, sort it never if you like."
            ]
        ),
        OnboardingPage(
            identifier: "career",
            title: "Career",
            subtitle: "Your private record of wins, impact, and stories.",
            systemImage: "briefcase",
            bullets: [
                "Log wins, impact moments, and interview-ready stories with supporting metrics.",
                "Use it to prep for reviews, recruiter calls, or your next career conversation.",
                "Records stay local — nothing is shared unless you choose to export it."
            ]
        ),
        OnboardingPage(
            identifier: "home",
            title: "Home",
            subtitle: "Recurring tasks and household protocols.",
            systemImage: "house",
            bullets: [
                "Track recurring chores and one-off tasks without losing visibility.",
                "Build multi-step protocols for routines like meal prep, travel, or move-out.",
                "Run a protocol to step through it once, and let Owlory remember the cadence."
            ]
        )
    ]
}

#Preview {
    OnboardingView(onComplete: {})
}
