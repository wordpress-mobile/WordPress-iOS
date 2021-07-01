import WordPressKit

extension RewindStatus {
    func isMultiSite() -> Bool {
        reason == "multisite_not_supported"
    }

    func isActive() -> Bool {
        state == .active
    }

    enum Strings {
        static let multisiteNotAvailable = NSLocalizedString("Jetpack Backup for Multisite installations provides downloadable backups, no one-click restores. For more information visit our documentation page.", comment: "Message for Jetpack users that have multisite WP installation, thus Restore is not available.")
        static let multisiteNotAvailableHighlight = NSLocalizedString("visit our documentation page", comment: "Portion of a message for Jetpack users that have multisite WP installation, thus Restore is not available. This part is a link, colored with a different color.")
    }
}
