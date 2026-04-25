import SwiftUI
import WidgetKit

struct OwloryTodayEntry: TimelineEntry {
    let date: Date
    let reminder: StoredReminderSpec?
}

struct StoredReminderSpec: Codable {
    let identifier: String
    let kind: String
    let title: String
    let body: String
    let deadline: Date
    let deepLinkURL: URL?
}

struct OwloryTodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> OwloryTodayEntry {
        OwloryTodayEntry(
            date: Date(),
            reminder: StoredReminderSpec(
                identifier: "today.check-in",
                kind: "check-in",
                title: "Check-in",
                body: "Take a quick read on energy, mood, and sleep.",
                deadline: Date(),
                deepLinkURL: URL(string: "owlory://open?route=today-prompt&kind=check-in")
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (OwloryTodayEntry) -> Void) {
        completion(OwloryTodayEntry(date: Date(), reminder: loadReminderSpecs().first))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OwloryTodayEntry>) -> Void) {
        let now = Date()
        let reminder = loadReminderSpecs().first
        completion(
            Timeline(
                entries: [OwloryTodayEntry(date: now, reminder: reminder)],
                policy: .after(
                    Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now
                )
            )
        )
    }

    private func loadReminderSpecs() -> [StoredReminderSpec] {
        guard let defaults = UserDefaults(suiteName: owloryWidgetAppGroupID) else { return [] }
        guard let data = defaults.data(forKey: owloryWidgetNotificationStorageKey) else { return [] }

        let decoder = JSONDecoder()
        let decoded = (try? decoder.decode([StoredReminderSpec].self, from: data)) ?? []
        return decoded.sorted {
            if $0.deadline == $1.deadline {
                return $0.identifier < $1.identifier
            }
            return $0.deadline < $1.deadline
        }
    }
}

struct OwloryTodayWidget: Widget {
    let kind = "OwloryTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: OwloryTodayProvider()
        ) { entry in
            OwloryTodayWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Reminder")
        .description("See the next Owlory reminder and open the related item.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct OwloryTodayWidgetView: View {
    let entry: OwloryTodayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: iconName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(iconColor)
                Spacer(minLength: 0)
                if let dueLabel {
                    Text(dueLabel)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Text(primaryText)
                .font(.headline)
                .lineLimit(2)
            Text(secondaryText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
        .widgetURL(entry.reminder?.deepLinkURL ?? URL(string: "owlory://open?route=today"))
    }

    private var primaryText: String {
        entry.reminder?.title ?? "All caught up"
    }

    private var secondaryText: String {
        guard let reminder = entry.reminder else {
            return "No pending reminders right now."
        }

        let body = reminder.body.trimmingCharacters(in: .whitespacesAndNewlines)
        return body.isEmpty ? "Open the related item from Today." : body
    }

    private var dueLabel: String? {
        guard let deadline = entry.reminder?.deadline else { return nil }
        return deadline.formatted(.dateTime.hour().minute())
    }

    private var iconName: String {
        switch entry.reminder?.kind {
        case "check-in":
            return "heart.text.clipboard"
        case "evening-reflection", "home-wrapped-reflection":
            return "moon.stars"
        case "prediction":
            return "bell.badge"
        default:
            return "checkmark.circle"
        }
    }

    private var iconColor: Color {
        switch entry.reminder?.kind {
        case "check-in":
            return .orange
        case "evening-reflection", "home-wrapped-reflection":
            return .indigo
        case "prediction":
            return .red
        default:
            return .green
        }
    }
}

private let owloryWidgetAppGroupID = "group.com.raelldottin.owlory.shared"
private let owloryWidgetNotificationStorageKey = "owlory.widget.notifications.v1"
