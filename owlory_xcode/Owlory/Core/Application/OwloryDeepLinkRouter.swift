import Combine
import Foundation
import UserNotifications

@MainActor
final class OwloryDeepLinkRouter: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published private(set) var pendingURL: URL?

    func clearPendingURL() {
        pendingURL = nil
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let rawURL = response.notification.request.content.userInfo[OwloryDeepLink.notificationUserInfoKey] as? String
        guard let rawURL, let url = URL(string: rawURL) else {
            completionHandler()
            return
        }

        Task { @MainActor in
            self.pendingURL = url
            completionHandler()
        }
    }
}
