import Foundation

enum OwloryDeepLink {
    static let notificationUserInfoKey = "owlory.deepLinkURL"

    enum Destination: Equatable {
        case today
        case todayPrompt(kind: String)
        case completionKey(String)
    }

    static func url(for destination: Destination) -> URL? {
        var components = URLComponents()
        components.scheme = "owlory"
        components.host = "open"

        switch destination {
        case .today:
            components.queryItems = [
                URLQueryItem(name: "route", value: "today")
            ]
        case .todayPrompt(let kind):
            components.queryItems = [
                URLQueryItem(name: "route", value: "today-prompt"),
                URLQueryItem(name: "kind", value: kind)
            ]
        case .completionKey(let key):
            components.queryItems = [
                URLQueryItem(name: "route", value: "completion-key"),
                URLQueryItem(name: "key", value: key)
            ]
        }

        return components.url
    }

    static func parse(_ url: URL) -> Destination? {
        guard url.scheme == "owlory",
              url.host == "open",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let queryItems = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
                item.value.map { (item.name, $0) }
            }
        )

        switch queryItems["route"] {
        case "today":
            return .today
        case "today-prompt":
            guard let kind = queryItems["kind"], !kind.isEmpty else { return .today }
            return .todayPrompt(kind: kind)
        case "completion-key":
            guard let key = queryItems["key"], !key.isEmpty else { return nil }
            return .completionKey(key)
        default:
            return nil
        }
    }

    static func completionKeyDomain(_ key: String) -> String? {
        let parts = key.split(separator: "|", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        return String(parts[0])
    }
}
