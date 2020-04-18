import Foundation

extension AbstractPost {
    static let passwordProtectedLabel = NSLocalizedString("Password protected", comment: "Privacy setting for posts set to 'Password protected'. Should be the same as in core WP.")
    static let privateLabel = NSLocalizedString("Private", comment: "Privacy setting for posts set to 'Private'. Should be the same as in core WP.")
    static let publicLabel = NSLocalizedString("Public", comment: "Privacy setting for posts set to 'Public' (default). Should be the same as in core WP.")

    /// A title describing the status. Ie.: "Public" or "Private" or "Password protected"
    @objc var titleForVisibility: String {
        if password != nil {
            return AbstractPost.passwordProtectedLabel
        } else if status == .publishPrivate {
            return AbstractPost.privateLabel
        }

        return AbstractPost.publicLabel
    }
}
