import WordPressKit

extension RewindStatus {
    func isMultisite() -> Bool {
        reason == "multisite_not_supported"
    }

    func isActive() -> Bool {
        state == .active
    }

    enum Strings {
        static let multisiteNotAvailable = String(format: Self.multisiteNotAvailableFormat,
                                                  Self.multisiteNotAvailableSubstring)
        static let multisiteNotAvailableFormat = NSLocalizedString("Jetpack Backup for Multisite installations provides downloadable backups, no one-click restores. For more information %1$@.", comment: "Message for Jetpack users that have multisite WP installation, thus Restore is not available. %1$@ is a placeholder for the string 'visit our documentation page'.")
        static let multisiteNotAvailableSubstring = NSLocalizedString("visit our documentation page", comment: "Portion of a message for Jetpack users that have multisite WP installation, thus Restore is not available. This part is a link, colored with a different color.")
    }
}
