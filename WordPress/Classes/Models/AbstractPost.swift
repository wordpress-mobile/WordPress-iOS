import Foundation

extension AbstractPost {
    /// Returns true if the post should be removed when the editor is closed without saving changes.
    @objc var shouldRemoveOnDismiss: Bool {
        return hasNeverAttemptedToUpload()
            || isRevision() && hasLocalChanges()
    }

    class func title(for status: Status) -> String {
        return AbstractPost.title(forStatus: status.rawValue)
    }

    /// Represent the supported properties used to sort posts.
    ///
    enum SortField {
        case dateCreated
        case dateModified

        /// The keyPath to access the underlying property.
        ///
        var keyPath: String {
            switch self {
            case .dateCreated:
                return #keyPath(AbstractPost.date_created_gmt)
            case .dateModified:
                return #keyPath(AbstractPost.dateModified)
            }
        }
    }

    @objc func containsGutenbergBlocks() -> Bool {
        return content?.contains("<!-- wp:") ?? false
    }
}
