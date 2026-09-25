import Foundation
import BuildSettingsKit
import FormattableContentKit

/// Which notifications the Notifications list shows.
enum NotificationsListScope {
    /// Every notification of the account.
    case all

    /// Reader-related notifications only: the kinds a person receives because of what they
    /// read, rather than because of activity on their own sites.
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
    /// and the notifications popover.
    ///
    /// It depends on the flag rather than on the app UI type because some live lists in the
    /// WordPress app, such as the iPad compact-width tab bar, ignore the UI type. Turning the
    /// flag off must leave those lists unscoped.
    static func forAppNavigation(
        app: AppBrand = BuildSettings.current.brand,
        isReaderAndNotificationsEnabled: Bool = FeatureFlag.readerAndNotificationsInWordPressApp.enabled
    ) -> NotificationsListScope {
        app == .wordpress && isReaderAndNotificationsEnabled ? .reader : .all
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
