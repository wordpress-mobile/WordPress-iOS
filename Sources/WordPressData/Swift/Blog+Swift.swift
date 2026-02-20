import Foundation
import CoreData

extension Blog {

    /// Stores the relationship to the `BlockEditorSettings` which is an optional entity that holds settings realated to the BlockEditor. These are features
    /// such as Global Styles and Full Site Editing settings and capabilities.
    ///
    @NSManaged public var blockEditorSettings: BlockEditorSettings?

    @objc
    public func supportsBlockEditorSettings() -> Bool {
        return hasRequiredWordPressVersion("5.8")
    }

    /// Returns the username to use for this site.
    ///
    /// For self-hosted sites, returns the stored `username`. For WordPress.com
    /// or Jetpack-connected sites, returns the account's username.
    @objc public var effectiveUsername: String? {
        if let username {
            return username
        } else if let account, isAccessibleThroughWPCom() {
            return account.username
        } else {
            return nil
        }
    }
}
