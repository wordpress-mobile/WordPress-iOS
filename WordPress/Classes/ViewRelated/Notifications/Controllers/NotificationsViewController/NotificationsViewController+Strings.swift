import Foundation

extension NotificationsViewController {

    enum Strings {
        enum NavigationBar {
            static let notificationSettingsActionTitle = NSLocalizedString(
                "notificationsViewController.navigationBar.action.settings",
                value: "Notification Settings",
                comment: "Link to Notification Settings section"
            )
            static let markAllAsReadActionTitle = NSLocalizedString(
                "notificationsViewController.navigationBar.action.markAllAsRead",
                value: "Mark All As Read",
                comment: "Marks all notifications under the filter as read"
            )
            static let menuButtonAccessibilityLabel = NSLocalizedString(
                "notificationsViewController.navigationBar.menu.accessibilityLabel",
                value: "Navigation Bar Menu Button",
                comment: "Accessibility label for the navigation bar menu button"
            )
        }
    }
}
