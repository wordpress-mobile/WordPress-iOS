import Foundation
import BuildSettingsKit
import FormattableContentKit

/// Which notifications the Notifications list shows.
enum NotificationsListScope {
    /// Every notification of the account.
    case all

    /// Reader notifications only: the kinds a person receives because of what they read,
    /// rather than because of activity on their own sites.
    ///
    /// The scope applies when fetching from the local store, not when syncing. Sync fetches
    /// the latest 100 notifications of the account, of every kind, and purges local notes
    /// outside that window. A person whose own sites generate more than 100 notifications newer
    /// than their latest Reader-related one therefore sees an empty list, and pull to refresh
    /// can't recover it. This risk was accepted. If it materializes, the notifications endpoint
    /// accepts a comma-separated `type` parameter, which allows a Reader-only sync or a union
    /// of the account-wide and Reader-only windows.
    case reader

    static let readerKinds: [NotificationKind] = [.newPost, .matcher, .commentLike]

    /// The scope of the lists that the app's navigation creates: the tab bar, the iPad sidebar,
    /// the notifications popover, and the Reader bell.
    ///
    /// It depends on the brand and the flag rather than on the resolved app UI type: a list can
    /// be built before a WordPress.com account exists, as the iPad compact tab bar is, when the
    /// UI type is still simplified, and the scope is set once at creation.
    static func forAppNavigation(
        app: AppBrand = BuildSettings.current.brand,
        isReaderInWordPressAppEnabled: Bool = JetpackFeaturesRemovalCoordinator.isReaderInWordPressAppEnabled
    ) -> NotificationsListScope {
        app == .wordpress && isReaderInWordPressAppEnabled ? .reader : .all
    }

    /// Whether a list with this scope, and the bell that opens it, use the account's new-activity
    /// state: the bell's badge, and the last-seen time that a visible list submits.
    ///
    /// That state covers every kind of notification, and the server keeps one last-seen time per
    /// account. A Reader list would badge its bell for activity it doesn't show, and opening it
    /// would mark that activity seen in the Jetpack app and on the web.
    var tracksAccountActivity: Bool {
        switch self {
        case .all:
            return true
        case .reader:
            return false
        }
    }

    /// The fetch predicate that limits notifications to this scope.
    var predicate: NSPredicate {
        switch self {
        case .all:
            return NSPredicate(value: true)
        case .reader:
            return NSPredicate(format: "type IN %@", Self.readerKinds.map(\.rawValue))
        }
    }
}
