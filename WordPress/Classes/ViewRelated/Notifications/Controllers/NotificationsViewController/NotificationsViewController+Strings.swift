import Foundation

extension NotificationsViewController {

    enum Strings {
        enum NavigationBar {
            static let notificationSettingsActionTitle = NSLocalizedString(
                "Notification Settings",
                comment: "Link to Notification Settings section"
            )
            static let markAllAsReadActionTitle = NSLocalizedString(
                "Mark All As Read",
                comment: "Marks all notifications under the filter as read"
            )
            static let menuButtonAccessibilityLabel = NSLocalizedString(
                "notifications.navigation.bar.menu.button.accessibility.label",
                value: "Navigation Bar Menu Button",
                comment: "Accessibility label for the navigation bar menu button"
            )
        }
    }
}
