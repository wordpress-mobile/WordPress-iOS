import Foundation

/// Shared localizable strings that can be used in different contexts.
enum SharedStrings {
    enum Button {
        static let ok = NSLocalizedString("shared.button.ok", value: "OK", comment: "A shared button title used in different contexts")
        static let cancel = NSLocalizedString("shared.button.cancel", value: "Cancel", comment: "A shared button title used in different contexts")
        static let close = NSLocalizedString("shared.button.close", value: "Close", comment: "A shared button title used in different contexts")
        static let done = NSLocalizedString("shared.button.done", value: "Done", comment: "A shared button title used in different contexts")
        static let edit = NSLocalizedString("shared.button.edit", value: "Edit", comment: "A shared button title used in different contexts")
        static let add = NSLocalizedString("shared.button.add", value: "Add", comment: "A shared button title used in different contexts")
        static let remove = NSLocalizedString("shared.button.remove", value: "Remove", comment: "A shared button title used in different contexts")
        static let delete = NSLocalizedString("shared.button.delete", value: "Delete", comment: "A shared button title used in different contexts")
        static let save = NSLocalizedString("shared.button.save", value: "Save", comment: "A shared button title used in different contexts")
        static let retry = NSLocalizedString("shared.button.retry", value: "Retry", comment: "A shared button title used in different contexts")
        static let view = NSLocalizedString("shared.button.view", value: "View", comment: "A shared button title used in different contexts")
        static let share = NSLocalizedString("shared.button.share", value: "Share", comment: "A shared button title used in different contexts")
        static let copy = NSLocalizedString("shared.button.copy", value: "Copy", comment: "A shared button title used in different contexts")
        static let copyLink = NSLocalizedString("shared.button.copyLink", value: "Copy Link", comment: "A shared button title used in different contexts")
        static let `continue` = NSLocalizedString("shared.button.continue", value: "Continue", comment: "A shared button title used in different contexts")
        static let undo = NSLocalizedString("shared.button.undo", value: "Undo", comment: "A shared button title used in different contexts")
    }

    enum Error {
        static let generic = NSLocalizedString("shared.error.geneirc", value: "Something went wrong", comment: "A generic error message")
        static let refreshFailed = NSLocalizedString("shared.error.failiedToReloadData", value: "Failed to update data", comment: "A generic error title indicating that a screen failed to fetch the latest data")
    }

    enum Reader {
        /// - warning: This is the legacy value. It's not compliant with the new format but has the correct translation for different languages.
        static let title = NSLocalizedString("Reader", comment: "The accessibility value of the Reader tab.")
        static let unfollow = NSLocalizedString("reader.button.unfollow", value: "Unfollow", comment: "Reader sidebar button title")
        static let subscribe = NSLocalizedString("reader.button.subscribe", value: "Subscribe", comment: "A shared button title for Reader")
        static let unsubscribe = NSLocalizedString("reader.button.unsubscribe", value: "Unsubscribe", comment: "A shared button title for Reader")
        static let addToFavorites = NSLocalizedString("reader.button.addToFavorites", value: "Add to Favorites", comment: "A shared button title for Reader")
        static let notificationSettings = NSLocalizedString("reader.button.notificationSettings", value: "Notification Settings", comment: "A shared button title for Reader")
        static let removeFromFavorites = NSLocalizedString("reader.button.removeFromFavorites", value: "Remove from Favorites", comment: "A shared button title for Reader")
        static let recent = NSLocalizedString("reader.recent.title", value: "Recent", comment: "Used in multiple contexts, usually as a screen title")
        static let discover = NSLocalizedString("reader.discover.title", value: "Discover", comment: "Used in multiple contexts, usually as a screen title")
        static let saved = NSLocalizedString("reader.saved.title", value: "Saved", comment: "Used in multiple contexts, usually as a screen title")
        static let likes = NSLocalizedString("reader.likes.title", value: "Likes", comment: "Used in multiple contexts, usually as a screen title")
    }
}
